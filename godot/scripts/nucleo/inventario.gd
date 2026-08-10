class_name Inventario
extends RefCounted
## Un contenedor de objetos. Nada más.
##
## Esta clase NO sabe de cadenas de suministro, ni de cuellos de botella, ni de
## reservas: eso vive en Almacen y ahí se queda. Aquí sólo hay "qué hay dentro
## y cuánto cabe".
##
## La idea es que con el tiempo la usen los cinco inventarios del juego —el del
## jugador, el de un NPC, el de un edificio, el de un barco y el del almacén—
## sin escribir cinco veces lo mismo. De momento la estrena la mochila del
## jugador; Almacen la adoptará cuando esto esté rodado.

signal cambiado(id: String, cantidad: int)
signal lleno(id: String, descartado: int)

## 0 = sin límite. En unidades de volumen de ItemData.
var capacidad: float = 0.0

var _items: Dictionary = {}          ## id -> int

func cantidad(id: String) -> int:
	return int(_items.get(id, 0))

func hay(id: String, n: int = 1) -> bool:
	return cantidad(id) >= n

func hay_todo(pedido: Dictionary) -> bool:
	for id in pedido:
		if cantidad(id) < int(pedido[id]):
			return false
	return true

func esta_vacio() -> bool:
	return _items.is_empty()

func ids() -> Array:
	return _items.keys()

## Volumen ocupado, según ItemData. Los ítems desconocidos cuentan 0.
func volumen() -> float:
	var v := 0.0
	for id in _items:
		var it: ItemData = BaseDeDatos.item(id)
		if it != null:
			v += it.volumen * int(_items[id])
	return v

func hueco_para(id: String) -> int:
	if capacidad <= 0.0:
		return 1 << 30
	var it: ItemData = BaseDeDatos.item(id)
	if it == null or it.volumen <= 0.0:
		return 1 << 30
	return maxi(0, int(floor((capacidad - volumen()) / it.volumen)))

## Devuelve cuánto entró de verdad, que puede ser menos de lo pedido.
func anadir(id: String, n: int = 1) -> int:
	if n <= 0:
		return 0
	var entra := mini(n, hueco_para(id))
	if entra < n:
		lleno.emit(id, n - entra)
	if entra <= 0:
		return 0
	_items[id] = cantidad(id) + entra
	cambiado.emit(id, _items[id])
	return entra

## Todo o nada: si no hay suficiente, no toca nada y devuelve false.
func retirar(id: String, n: int = 1) -> bool:
	if n <= 0:
		return true
	if cantidad(id) < n:
		return false
	_items[id] = cantidad(id) - n
	if _items[id] <= 0:
		_items.erase(id)
	cambiado.emit(id, cantidad(id))
	return true

## Retira lo que pueda y dice cuánto se llevó. Para mermas y saqueos.
func retirar_hasta(id: String, n: int) -> int:
	var se_va := mini(n, cantidad(id))
	if se_va > 0:
		retirar(id, se_va)
	return se_va

## Mueve objetos de este inventario a otro sin que se pierda ni se duplique
## nada por el camino: si en el destino sólo caben 3 de los 5, aquí se quedan 2.
func transferir_a(destino: Inventario, id: String, n: int) -> int:
	if destino == null or n <= 0:
		return 0
	var disponible := mini(n, cantidad(id))
	if disponible <= 0:
		return 0
	var aceptado := destino.anadir(id, disponible)
	if aceptado > 0:
		retirar(id, aceptado)
	return aceptado

## Consume un lote completo, usando sustitutos de emergencia si hace falta.
## Mantiene la misma semántica de Almacen.consumir, pero sin conocer logística.
## El plan se valida entero antes de retirar nada.
func consumir_con_sustitutos(insumos: Dictionary, sustitutos: Dictionary = {}) -> Dictionary:
	var plan: Dictionary = {}
	var faltan: Dictionary = {}
	var cambios: Array = []
	var calidad := 1.0

	for id in insumos:
		var necesita := int(insumos[id])
		var toma := mini(necesita, _libre_para_consumo(str(id), plan))
		if toma > 0:
			plan[str(id)] = int(plan.get(str(id), 0)) + toma
		var resto := necesita - toma
		if resto > 0 and sustitutos.has(id):
			var s: Dictionary = sustitutos[id]
			var sid := str(s.get("id", ""))
			var ratio := maxf(0.0001, float(s.get("ratio", 1.0)))
			var hacen_falta := int(ceil(resto * ratio))
			var hay := _libre_para_consumo(sid, plan)
			if hay >= hacen_falta:
				plan[sid] = int(plan.get(sid, 0)) + hacen_falta
				calidad = minf(calidad, float(s.get("calidad", 1.0)))
				cambios.append({"original": str(id), "sustituto": sid, "cantidad": hacen_falta})
				resto = 0
			elif hay > 0:
				var cubre := int(floor(hay / ratio))
				if cubre > 0:
					var gasta := int(ceil(cubre * ratio))
					plan[sid] = int(plan.get(sid, 0)) + gasta
					calidad = minf(calidad, float(s.get("calidad", 1.0)))
					cambios.append({"original": str(id), "sustituto": sid, "cantidad": gasta})
					resto -= cubre
		if resto > 0:
			faltan[str(id)] = resto

	if not faltan.is_empty():
		return {"ok": false, "gasto": {}, "faltan": faltan, "sustituciones": [], "calidad": 0.0}

	for id in plan:
		if not retirar(str(id), int(plan[id])):
			push_error("Inventario: el plan de consumo dejó de ser válido para %s" % id)
			return {"ok": false, "gasto": {}, "faltan": {str(id): int(plan[id])}, "sustituciones": [], "calidad": 0.0}
	return {"ok": true, "gasto": plan, "faltan": {}, "sustituciones": cambios, "calidad": calidad}

func _libre_para_consumo(id: String, plan: Dictionary) -> int:
	return maxi(0, cantidad(id) - int(plan.get(id, 0)))

func vaciar() -> void:
	var previos := _items.keys()
	_items.clear()
	for id in previos:
		cambiado.emit(id, 0)

## Lista ordenada por nombre, para pintar en pantalla.
func lista() -> Array:
	var filas := []
	for id in _items:
		filas.append({
			"id": id,
			"nombre": BaseDeDatos.nombre_item(id),
			"cantidad": int(_items[id]),
		})
	filas.sort_custom(func(a, b): return a["nombre"] < b["nombre"])
	return filas

# ---------------------------------------------------------------------------
# GUARDADO
# ---------------------------------------------------------------------------

func serializar() -> Dictionary:
	return { "items": _items.duplicate(), "capacidad": capacidad }

func cargar(datos: Dictionary) -> void:
	_items = (datos.get("items", {}) as Dictionary).duplicate()
	capacidad = float(datos.get("capacidad", 0.0))
