extends Node
## AUTOLOAD: Almacen  (el "InventoryManager" del prompt)
##
## No es un inventario de RPG. Es el nodo central de una cadena de suministro:
##
##   1. CUELLOS DE BOTELLA — cada estación registra sus insumos críticos con un
##      mínimo. Cuando se cae por debajo, se emite `cuello_de_botella` UNA vez
##      (no un spam por frame) y `cuello_resuelto` cuando se recupera.
##
##   2. SUSTITUCIÓN DE MATERIA PRIMA — `consumir()` no falla en cuanto falta algo.
##      Primero intenta rellenar el hueco con el sustituto de emergencia definido
##      en la receta, a su ratio, y devuelve la calidad resultante del lote.
##
##   3. RESERVAS — una estación puede apartar material para su lote en curso, de
##      forma que otra no se lo quite a media producción. Esto es lo que evita el
##      clásico bug de "dos edificios gastaron el mismo tablón".
##
## El rastreo de dónde está la carga (mar / puerto / cofres) vive en RastreoCarga;
## este nodo sólo gobierna los cofres de la ciudad.

signal existencias_cambiadas(id: String, cantidad: int)
signal cuello_de_botella(estacion_id: String, insumo_id: String, faltan: int)
signal cuello_resuelto(estacion_id: String, insumo_id: String)
signal sustitucion_aplicada(estacion_id: String, original: String, sustituto: String, cantidad: int)
signal almacen_lleno(id: String, descartado: int)
signal robo(ladron: String, id: String, cantidad: int)

## Capacidad total en volumen. 0 = sin límite (útil mientras pruebas).
@export var capacidad_volumen: float = 0.0

var existencias: Dictionary = {}         ## id -> int
var reservas: Dictionary = {}            ## id -> int (apartado, no disponible)

var _umbrales: Dictionary = {}           ## "estacion|insumo" -> int mínimo
var _alertas: Dictionary = {}            ## "estacion|insumo" -> true si ya avisamos

# ---------------------------------------------------------------------------
# CONSULTA
# ---------------------------------------------------------------------------

func cantidad(id: String) -> int:
	return int(existencias.get(id, 0))

## Lo que se puede tocar de verdad: el total menos lo que otra estación apartó.
func disponible(id: String) -> int:
	return maxi(0, cantidad(id) - int(reservas.get(id, 0)))

func hay_todo(insumos: Dictionary) -> bool:
	for id in insumos:
		if disponible(id) < int(insumos[id]):
			return false
	return true

func volumen_ocupado() -> float:
	var v := 0.0
	for id in existencias:
		var it: ItemData = BaseDeDatos.item(id)
		if it != null:
			v += it.volumen * existencias[id]
	return v

# ---------------------------------------------------------------------------
# ENTRADAS Y SALIDAS
# ---------------------------------------------------------------------------

## Devuelve cuánto entró de verdad (puede ser menos si el almacén está lleno).
func anadir(id: String, n: int, _origen: String = "") -> int:
	if n <= 0:
		return 0
	var it: ItemData = BaseDeDatos.item(id)
	if it == null:
		push_warning("Almacen: ítem desconocido '%s'" % id)
		return 0

	# La moral no se guarda en cofres: se convierte en alivio de motín al vuelo.
	if it.es_intangible():
		if id == "moral":
			Motin.aliviar(float(n))
		return n

	var entra := n
	if capacidad_volumen > 0.0 and it.volumen > 0.0:
		var sitio := int(floor((capacidad_volumen - volumen_ocupado()) / it.volumen))
		entra = mini(n, maxi(0, sitio))
		if entra < n:
			almacen_lleno.emit(id, n - entra)
	if entra <= 0:
		return 0

	existencias[id] = cantidad(id) + entra
	existencias_cambiadas.emit(id, existencias[id])
	_revisar_alertas(id)
	return entra

func retirar(id: String, n: int) -> bool:
	if n <= 0:
		return true
	if disponible(id) < n:
		return false
	existencias[id] = cantidad(id) - n
	if existencias[id] <= 0:
		existencias.erase(id)
	existencias_cambiadas.emit(id, cantidad(id))
	_revisar_alertas(id)
	return true

## Retira lo que pueda y devuelve cuánto se llevó. Para plagas y mermas.
func mermar(id: String, n: int, culpable: String = "") -> int:
	var se_va := mini(n, disponible(id))
	if se_va <= 0:
		return 0
	retirar(id, se_va)
	if culpable != "":
		robo.emit(culpable, id, se_va)
	return se_va

# ---------------------------------------------------------------------------
# RESERVAS
# ---------------------------------------------------------------------------

func reservar(insumos: Dictionary) -> bool:
	if not hay_todo(insumos):
		return false
	for id in insumos:
		reservas[id] = int(reservas.get(id, 0)) + int(insumos[id])
	return true

func liberar_reserva(insumos: Dictionary) -> void:
	for id in insumos:
		reservas[id] = maxi(0, int(reservas.get(id, 0)) - int(insumos[id]))
		if reservas[id] == 0:
			reservas.erase(id)

# ---------------------------------------------------------------------------
# 1 + 2: CONSUMO CON SUSTITUCIÓN Y AVISO DE CUELLO DE BOTELLA
# ---------------------------------------------------------------------------

## El método importante. Planifica ANTES de tocar nada, y sólo si el plan
## completo es viable ejecuta el gasto. Nunca deja el almacén a medio consumir.
##
## Devuelve:
##   {
##     ok: bool,
##     gasto: { id -> cantidad realmente gastada },
##     faltan: { id -> cuánto faltó },            (vacío si ok)
##     sustituciones: [ {original, sustituto, cantidad} ],
##     calidad: float                              (1.0 = lote perfecto)
##   }
func consumir(insumos: Dictionary, estacion_id: String = "", sustitutos: Dictionary = {}) -> Dictionary:
	var plan: Dictionary = {}
	var faltan: Dictionary = {}
	var cambios: Array = []
	var calidad := 1.0

	for id in insumos:
		var necesita := int(insumos[id])

		# a) lo que se pueda con el material correcto
		var toma := mini(necesita, _libre(id, plan))
		if toma > 0:
			plan[id] = int(plan.get(id, 0)) + toma
		var resto := necesita - toma

		# b) el hueco, con el sustituto de emergencia
		if resto > 0 and sustitutos.has(id):
			var s: Dictionary = sustitutos[id]
			var sid: String = s.get("id", "")
			var ratio := float(s.get("ratio", 1.0))
			var hacen_falta := int(ceil(resto * ratio))
			var hay := _libre(sid, plan)
			if hay >= hacen_falta:
				plan[sid] = int(plan.get(sid, 0)) + hacen_falta
				calidad = minf(calidad, float(s.get("calidad", 1.0)))
				cambios.append({ "original": id, "sustituto": sid, "cantidad": hacen_falta })
				resto = 0
			elif hay > 0:
				# sustitución parcial: cubre lo que pueda, el resto sigue faltando
				var cubre := int(floor(hay / ratio))
				if cubre > 0:
					var gasta := int(ceil(cubre * ratio))
					plan[sid] = int(plan.get(sid, 0)) + gasta
					calidad = minf(calidad, float(s.get("calidad", 1.0)))
					cambios.append({ "original": id, "sustituto": sid, "cantidad": gasta })
					resto -= cubre

		if resto > 0:
			faltan[id] = resto

	if not faltan.is_empty():
		for id in faltan:
			_avisar_cuello(estacion_id, id, faltan[id])
		return { "ok": false, "gasto": {}, "faltan": faltan, "sustituciones": [], "calidad": 0.0 }

	# plan viable -> ahora sí, se gasta
	for id in plan:
		existencias[id] = cantidad(id) - int(plan[id])
		if existencias[id] <= 0:
			existencias.erase(id)
		existencias_cambiadas.emit(id, cantidad(id))

	for c in cambios:
		sustitucion_aplicada.emit(estacion_id, c["original"], c["sustituto"], c["cantidad"])

	for id in plan:
		_revisar_alertas(id)

	return { "ok": true, "gasto": plan, "faltan": {}, "sustituciones": cambios, "calidad": calidad }

## Cuánto queda de un ítem descontando lo ya comprometido en este mismo plan.
func _libre(id: String, plan: Dictionary) -> int:
	return maxi(0, disponible(id) - int(plan.get(id, 0)))

# ---------------------------------------------------------------------------
# UMBRALES CRÍTICOS (el aviso temprano, antes de que la estación pare)
# ---------------------------------------------------------------------------

## La Taberna llama a esto al arrancar:
##   Almacen.vigilar("taberna", "ron", 6)
## y a partir de ahí recibes aviso en cuanto el ron baje de 6, sin esperar
## a que la producción se detenga.
func vigilar(estacion_id: String, insumo_id: String, minimo: int) -> void:
	_umbrales["%s|%s" % [estacion_id, insumo_id]] = minimo
	_revisar_alertas(insumo_id)

func dejar_de_vigilar(estacion_id: String, insumo_id: String) -> void:
	var k := "%s|%s" % [estacion_id, insumo_id]
	_umbrales.erase(k)
	_alertas.erase(k)

## Lista de todo lo que está en rojo ahora mismo. La UI lee esto.
func cuellos_activos() -> Array:
	var res := []
	for k in _alertas:
		var partes: PackedStringArray = k.split("|")
		var minimo := int(_umbrales.get(k, 0))
		res.append({
			"estacion": partes[0],
			"insumo": partes[1],
			"hay": cantidad(partes[1]),
			"minimo": minimo,
		})
	return res

func _revisar_alertas(id_cambiado: String) -> void:
	for k in _umbrales:
		var partes: PackedStringArray = k.split("|")
		if partes[1] != id_cambiado:
			continue
		var minimo := int(_umbrales[k])
		var hay := disponible(partes[1])
		if hay < minimo and not _alertas.has(k):
			_alertas[k] = true
			cuello_de_botella.emit(partes[0], partes[1], minimo - hay)
		elif hay >= minimo and _alertas.has(k):
			_alertas.erase(k)
			cuello_resuelto.emit(partes[0], partes[1])

func _avisar_cuello(estacion_id: String, insumo_id: String, faltan_n: int) -> void:
	if estacion_id == "":
		return
	var k := "%s|%s" % [estacion_id, insumo_id]
	if _alertas.has(k):
		return                       # ya estaba avisado: no repetir cada frame
	_alertas[k] = true
	if not _umbrales.has(k):
		_umbrales[k] = faltan_n      # aprende el umbral de la propia receta
	cuello_de_botella.emit(estacion_id, insumo_id, faltan_n)

# ---------------------------------------------------------------------------
# UTILIDAD
# ---------------------------------------------------------------------------

func resumen() -> Array:
	var filas := []
	for id in existencias:
		var it: ItemData = BaseDeDatos.item(id)
		filas.append({
			"id": id,
			"nombre": it.nombre if it != null else id,
			"cantidad": existencias[id],
			"reservado": int(reservas.get(id, 0)),
		})
	filas.sort_custom(func(a, b): return a["nombre"] < b["nombre"])
	return filas

func vaciar() -> void:
	existencias.clear()
	reservas.clear()
	_alertas.clear()
