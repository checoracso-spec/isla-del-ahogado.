extends Node
## AUTOLOAD: RastreoCarga
##
## Punto 3 del prompt: saber en todo momento qué mercancía está EN EL MAR,
## cuál ha atracado y espera EN EL PUERTO, y cuál ya está EN LOS COFRES.
##
## Ese hueco entre "atracó" y "está en el almacén" es intencional: descargar
## cuesta tiempo y gente, así que un puerto saturado es un cuello de botella
## real, no decorativo.
##
## Un manifiesto es un diccionario:
##   { id, barco, contenido {item->n}, destino, dias_total, dias_restantes,
##     estado, canones, riesgo }

signal cargamento_zarpo(manifiesto: Dictionary)
signal informe_interceptacion(manifiesto: Dictionary)      ## hay que decidir: soltar o luchar
signal cargamento_atracado(manifiesto: Dictionary)
signal cargamento_perdido(manifiesto: Dictionary, motivo: String)
signal carga_descargada(manifiesto: Dictionary)

enum Ubicacion { EN_MAR, EN_PUERTO, EN_COFRES }

const BARCOS := {
	"balandra":  { "nombre": "Balandra",  "volumen": 40.0,  "peso": 30.0,  "canones_max": 4 },
	"bergantin": { "nombre": "Bergantín", "volumen": 110.0, "peso": 90.0,  "canones_max": 12 },
	"galeon":    { "nombre": "Galeón",    "volumen": 260.0, "peso": 240.0, "canones_max": 28 },
}

## Rutas disponibles para la interfaz del muelle.
## El panel solo usa el id; la carga, el barco y la duracion viven aqui.
const RUTAS := {
	"portobello": {
		"nombre": "Ruta de Portobello",
		"barco": "bergantin",
		"contenido": { "seda_robada": 2, "tablon_tratado": 2 },
		"canones": 2,
		"dias": 3,
	},
	"isla_ceniza": {
		"nombre": "Ruta de Isla Ceniza",
		"barco": "balandra",
		"contenido": { "madera_naufragio": 2, "polvora_humeda": 1 },
		"canones": 1,
		"dias": 2,
	}
}

var manifiestos: Dictionary = {}          ## id -> manifiesto
var _siguiente_id: int = 1

func _ready() -> void:
	Reloj.nuevo_dia.connect(_pasar_dia)
	Guardado.registrar("rastreo_carga", _serializar, _cargar)

func _serializar() -> Dictionary:
	return {
		"siguiente_id": _siguiente_id,
		"manifiestos": manifiestos.duplicate(true),
	}

func _cargar(datos: Dictionary) -> void:
	_siguiente_id = maxi(1, int(datos.get("siguiente_id", 1)))
	manifiestos.clear()
	var guardados: Dictionary = datos.get("manifiestos", {})
	for id in guardados:
		manifiestos[str(id)] = guardados[id].duplicate(true)

# ---------------------------------------------------------------------------
# APROVISIONAR Y ZARPAR
# ---------------------------------------------------------------------------

## Cuántos cañones más carga caben. Aquí está el dilema del diseño:
## cada cañón que subes es bodega que pierdes para el botín.
func capacidad(barco: String) -> Dictionary:
	var b: Dictionary = BARCOS.get(barco, {})
	if b.is_empty():
		return { "volumen": 0.0, "peso": 0.0, "canones_max": 0 }
	var extra := Plantel.factor("capacidad_carga")      # Anne Bonny: +15%
	return {
		"volumen": float(b["volumen"]) * extra,
		"peso": float(b["peso"]) * extra,
		"canones_max": int(b["canones_max"]),
	}

func medir(contenido: Dictionary, canones: int = 0) -> Dictionary:
	var vol := 0.0
	var pes := 0.0
	for id in contenido:
		var it: ItemData = BaseDeDatos.item(id)
		if it == null:
			continue
		vol += it.volumen * int(contenido[id])
		pes += it.peso * int(contenido[id])
	var c: ItemData = BaseDeDatos.item("canon")
	if c != null:
		vol += c.volumen * canones
		pes += c.peso * canones
	return { "volumen": vol, "peso": pes }

func ruta(id: String) -> Dictionary:
	return RUTAS.get(id, {}).duplicate(true)

func rutas_disponibles() -> Array[String]:
	var ids: Array[String] = []
	for id in RUTAS.keys():
		ids.append(str(id))
	ids.sort()
	return ids

## Despacha una ruta definida por datos, sin duplicar la logica de zarpar().
func zarpar_ruta(id: String) -> String:
	var r := ruta(id)
	if r.is_empty():
		push_warning("Ruta desconocida: %s" % id)
		return ""
	return zarpar(
		str(r["barco"]),
		r["contenido"],
		int(r["canones"]),
		str(r["nombre"]),
		int(r["dias"]))

func cabe(barco: String, contenido: Dictionary, canones: int) -> bool:
	var cap := capacidad(barco)
	if canones > int(cap["canones_max"]):
		return false
	var med := medir(contenido, canones)
	return med["volumen"] <= cap["volumen"] and med["peso"] <= cap["peso"]

## Saca la carga de los cofres y la manda al mar. Devuelve el id del manifiesto,
## o "" si no cabe o no hay material.
func zarpar(barco: String, contenido: Dictionary, canones: int, destino: String, dias: int) -> String:
	if not BARCOS.has(barco):
		push_warning("Barco desconocido: %s" % barco)
		return ""
	if not cabe(barco, contenido, canones):
		push_warning("No cabe en la %s: revisa cañones vs bodega." % barco)
		return ""

	var carga_total := contenido.duplicate()
	if canones > 0:
		carga_total["canon"] = int(carga_total.get("canon", 0)) + canones
	var res := Almacen.consumir(carga_total, "capitania")
	if not res["ok"]:
		return ""

	var dias_reales := maxi(1, int(round(dias * Plantel.factor("tiempo_expedicion"))))
	var m := {
		"id": "exp_%d" % _siguiente_id,
		"barco": barco,
		"contenido": contenido.duplicate(),
		"canones": canones,
		"destino": destino,
		"dias_total": dias_reales,
		"dias_restantes": dias_reales,
		"estado": Ubicacion.EN_MAR,
		"riesgo": _riesgo_base(canones),
		"interceptado": false,
	}
	_siguiente_id += 1
	manifiestos[m["id"]] = m
	cargamento_zarpo.emit(m)
	return m["id"]

func _riesgo_base(canones: int) -> float:
	# Más cañones, menos riesgo. El faro y Ojo de Vidrio lo bajan más.
	var r := 0.22 - canones * 0.012
	r *= Plantel.factor("riesgo_naufragio", "faro")     # Ojo de Vidrio en el faro
	r *= maxf(0.3, 1.0 - Plantel.modificador("defensa"))  # Charles Vane
	return clampf(r, 0.02, 0.6)

# ---------------------------------------------------------------------------
# AVANCE DIARIO
# ---------------------------------------------------------------------------

func _pasar_dia(_dia: int) -> void:
	for id in manifiestos.keys():
		var m: Dictionary = manifiestos[id]
		if m["estado"] != Ubicacion.EN_MAR:
			continue
		m["dias_restantes"] = int(m["dias_restantes"]) - 1

		if not m["interceptado"] and randf() < float(m["riesgo"]) * 0.5:
			m["interceptado"] = true
			informe_interceptacion.emit(m)
			continue                      # ese día no avanza más: esperas tu decisión

		if int(m["dias_restantes"]) <= 0:
			m["estado"] = Ubicacion.EN_PUERTO
			cargamento_atracado.emit(m)

## Respuesta a un informe de interceptación.
## "soltar": tiras lo más pesado y escapas seguro.
## "luchar": tiras los dados con tus cañones de por medio.
func resolver_interceptacion(id: String, decision: String) -> void:
	if not manifiestos.has(id):
		return
	var m: Dictionary = manifiestos[id]
	m["interceptado"] = false

	if decision == "soltar":
		var mas_pesado := ""
		var peor := -1.0
		for iid in m["contenido"]:
			var it: ItemData = BaseDeDatos.item(iid)
			if it == null:
				continue
			var lastre := it.peso * int(m["contenido"][iid])
			if lastre > peor:
				peor = lastre
				mas_pesado = iid
		if mas_pesado != "":
			m["contenido"].erase(mas_pesado)
		m["riesgo"] = float(m["riesgo"]) * 0.4
	else:
		var prob_victoria := clampf(0.35 + int(m["canones"]) * 0.05, 0.1, 0.95)
		if randf() > prob_victoria:
			manifiestos.erase(id)                 # se acabó: ni carga ni barco
			cargamento_perdido.emit(m, "hundido por la Marina")
			return
		# victoria: si Grace está en plantilla, además cobras rescate
		if Plantel.tiene_capacidad("rescate_automatico"):
			m["contenido"]["doblon"] = int(m["contenido"].get("doblon", 0)) + 150

# ---------------------------------------------------------------------------
# DESCARGA: PUERTO -> COFRES
# ---------------------------------------------------------------------------

func descargar(id: String) -> bool:
	if not manifiestos.has(id):
		return false
	var m: Dictionary = manifiestos[id]
	if m["estado"] != Ubicacion.EN_PUERTO:
		return false
	for iid in m["contenido"]:
		Almacen.anadir(iid, int(m["contenido"][iid]), "expedicion")
	if int(m["canones"]) > 0:
		Almacen.anadir("canon", int(m["canones"]), "expedicion")
	m["estado"] = Ubicacion.EN_COFRES
	manifiestos.erase(id)
	carga_descargada.emit(m)
	return true

func descargar_todo() -> int:
	var n := 0
	for id in manifiestos.keys():
		if manifiestos[id]["estado"] == Ubicacion.EN_PUERTO and descargar(id):
			n += 1
	return n

# ---------------------------------------------------------------------------
# LA FOTO GLOBAL
# ---------------------------------------------------------------------------

## id_item -> { mar, puerto, cofres, total }
## Con esto puedes responder "tengo 40 pólvoras" aunque 30 estén flotando.
func inventario_global() -> Dictionary:
	var res: Dictionary = {}
	for id in Almacen.existencias:
		res[id] = { "mar": 0, "puerto": 0, "cofres": int(Almacen.existencias[id]), "total": 0 }
	for mid in manifiestos:
		var m: Dictionary = manifiestos[mid]
		var clave := "mar" if m["estado"] == Ubicacion.EN_MAR else "puerto"
		var todo: Dictionary = m["contenido"].duplicate()
		if int(m["canones"]) > 0:
			todo["canon"] = int(todo.get("canon", 0)) + int(m["canones"])
		for iid in todo:
			if not res.has(iid):
				res[iid] = { "mar": 0, "puerto": 0, "cofres": 0, "total": 0 }
			res[iid][clave] = int(res[iid][clave]) + int(todo[iid])
	for iid in res:
		res[iid]["total"] = res[iid]["mar"] + res[iid]["puerto"] + res[iid]["cofres"]
	return res

func en_mar() -> Array:
	return manifiestos.values().filter(func(m): return m["estado"] == Ubicacion.EN_MAR)

func en_puerto() -> Array:
	return manifiestos.values().filter(func(m): return m["estado"] == Ubicacion.EN_PUERTO)
