extends Node
## AUTOLOAD: Motin
##
## El Medidor de Motín sustituye a la barra de felicidad de Medieval Dynasty.
## Sube solo. Bajarlo cuesta suministros. Tres presiones distintas:
##
##   RACIONES (cada amanecer)  — sin comida, sube rápido.
##   PAGA     (cada amanecer)  — sin doblones, sube rápido.
##   RON      (cada anochecer) — lo sirve la Taberna; si la Taberna está parada
##                               por falta de insumos, nadie lo compensa.
##
## Por eso el motín es en realidad un problema de LOGÍSTICA, no de un número:
## se dispara cuando se rompe una cadena de suministro, no al azar.

signal nivel_cambiado(nivel: float)
signal umbral_cruzado(nombre: String, nivel: float)     ## calma / tension / peligro / revuelta
signal incidente(tipo: String, detalle: String)
signal carencia(id_item: String, faltaban: int)

const RACIONES_POR_PIRATA := 1.0
const RON_POR_PIRATA := 0.5
const PAGA_POR_PIRATA := 4

const SUBIDA_SIN_COMIDA := 18.0
const SUBIDA_SIN_PAGA := 12.0
const SUBIDA_SIN_RON := 9.0
const BAJADA_DIA_BUENO := 7.0

var nivel: float = 12.0
var tripulacion: int = 8

var _umbral_actual: String = "calma"

func _ready() -> void:
	Reloj.nuevo_dia.connect(_amanecer)
	Reloj.anochecer.connect(_anochecer)

# ---------------------------------------------------------------------------
# ENTRADA DE ALIVIO (la usa la Taberna a través de Almacen.anadir("moral", n))
# ---------------------------------------------------------------------------

func aliviar(puntos: float) -> void:
	# Black Sam multiplica el efecto de todo lo que sube la moral.
	_ajustar(-puntos * Plantel.factor("moral_global"))

func agravar(puntos: float, motivo: String = "") -> void:
	_ajustar(puntos)
	if motivo != "":
		incidente.emit("presion", motivo)

func _ajustar(delta: float) -> void:
	var antes := nivel
	nivel = clampf(nivel + delta, 0.0, 100.0)
	if not is_equal_approx(antes, nivel):
		nivel_cambiado.emit(nivel)
		_revisar_umbral()

func _revisar_umbral() -> void:
	var nuevo := estado_texto()
	if nuevo != _umbral_actual:
		_umbral_actual = nuevo
		umbral_cruzado.emit(nuevo, nivel)
		if nuevo == "revuelta":
			_estallar()

func estado_texto() -> String:
	if nivel < 25.0:
		return "calma"
	elif nivel < 50.0:
		return "tension"
	elif nivel < 80.0:
		return "peligro"
	return "revuelta"

# ---------------------------------------------------------------------------
# CONSUMO DIARIO
# ---------------------------------------------------------------------------

func _amanecer(_dia: int) -> void:
	var contento := true

	# comida — Dientes de Oro estira las raciones
	var necesita_com := int(ceil(tripulacion * RACIONES_POR_PIRATA * Plantel.factor("consumo_raciones")))
	var res_com := Almacen.consumir({ "raciones": necesita_com }, "campamento")
	if not res_com["ok"]:
		var faltan_com := int(res_com["faltan"].get("raciones", necesita_com))
		Almacen.mermar("raciones", necesita_com)          # se comen lo que haya
		carencia.emit("raciones", faltan_com)
		_ajustar(SUBIDA_SIN_COMIDA)
		contento = false

	# paga
	var necesita_oro := tripulacion * PAGA_POR_PIRATA
	var res_oro := Almacen.consumir({ "doblon": necesita_oro }, "alcaldia")
	if not res_oro["ok"]:
		carencia.emit("doblon", int(res_oro["faltan"].get("doblon", necesita_oro)))
		_ajustar(SUBIDA_SIN_PAGA)
		contento = false

	if contento:
		_ajustar(-BAJADA_DIA_BUENO)

	_plagas()

func _anochecer(_dia: int) -> void:
	# Si la Taberna funcionó, ya habrá inyectado moral por su cuenta.
	# Esto sólo castiga la noche seca: no queda ron en ninguna parte.
	var necesita_ron := int(ceil(tripulacion * RON_POR_PIRATA * Plantel.factor("consumo_ron", "taberna")))
	if Almacen.disponible("ron") < necesita_ron:
		carencia.emit("ron", necesita_ron - Almacen.disponible("ron"))
		_ajustar(SUBIDA_SIN_RON)

# ---------------------------------------------------------------------------
# CONSECUENCIAS
# ---------------------------------------------------------------------------

func _estallar() -> void:
	# Black Bart redactó las leyes: nadie roba del almacén.
	var pueden_robar := Plantel.modificador("robo_almacen") >= 0.0

	if pueden_robar and randf() < 0.6:
		var candidatos := Almacen.existencias.keys().filter(func(id):
			return int(Almacen.existencias[id]) > 0)
		if not candidatos.is_empty():
			var botin: String = candidatos.pick_random()
			var se_llevan := maxi(1, int(Almacen.cantidad(botin) * 0.35))
			Almacen.mermar(botin, se_llevan, "tripulación amotinada")
			incidente.emit("robo", "Se llevaron %d de %s." % [se_llevan, BaseDeDatos.nombre_item(botin)])
			_ajustar(-15.0)
			return

	incidente.emit("sabotaje", "Han destrozado una instalación. La producción se resiente.")
	_ajustar(-10.0)

func _plagas() -> void:
	for a: AnimalData in BaseDeDatos.animales.values():
		if a.tipo != "plaga":
			continue
		if _neutralizada(a):
			continue
		for id in a.consume:
			var n := int(a.consume[id])
			if Almacen.disponible(id) >= n and randf() < 0.5:
				Almacen.mermar(id, n, a.nombre)
				incidente.emit("plaga", "%s: -%d %s" % [a.nombre, n, BaseDeDatos.nombre_item(id)])

## Placeholder honesto: cuando existan mejoras de almacén, léelas aquí.
func _neutralizada(a: AnimalData) -> bool:
	if a == null or a.contramedida == "":
		return false
	if a.contramedida == "cofre_nivel_2":
		return false
	return AnimalesMundo.tiene_domestico(a.contramedida)

# ---------------------------------------------------------------------------

func color_barra() -> Color:
	match estado_texto():
		"calma": return Color("4caf50")
		"tension": return Color("d4a017")
		"peligro": return Color("e07b39")
		_: return Color("c0392b")
