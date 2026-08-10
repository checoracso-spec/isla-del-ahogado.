extends Node
## AUTOLOAD: AnimalesMundo
##
## Registro de estado plano de animales vivos. La entidad Node2D es temporal;
## esta tabla conserva identidad, posición y estado para guardar/cargar sin
## serializar referencias al árbol.

signal animal_cambiado(instancia: String)
signal produccion_diaria(instancia: String, productos: Dictionary)

var _estados: Dictionary = {}
var _vivas: Dictionary = {}

func _ready() -> void:
	Guardado.registrar("animales_mundo", _serializar, _cargar)
	Reloj.nuevo_dia.connect(_procesar_nuevo_dia)

func registrar(animal: Node) -> bool:
	if animal == null:
		return false
	var identidad: Identidad = animal.get("identidad") as Identidad
	if identidad == null:
		return false
	var id := str(identidad.instancia)
	_vivas[id] = animal
	if _estados.has(id):
		animal.call("aplicar_estado", _estados[id])
	else:
		_estados[id] = animal.call("serializar")
	if not animal.tree_exiting.is_connected(_al_salir.bind(id)):
		animal.tree_exiting.connect(_al_salir.bind(id), CONNECT_ONE_SHOT)
	return true

func anotar(animal: Node) -> void:
	if animal == null:
		return
	var identidad: Identidad = animal.get("identidad") as Identidad
	if identidad == null:
		return
	var id := str(identidad.instancia)
	if not _estados.has(id):
		return
	_estados[id] = animal.call("serializar")
	animal_cambiado.emit(id)

func estado(instancia: String) -> Dictionary:
	return (_estados.get(instancia, {}) as Dictionary).duplicate(true)

func tiene_domestico(definicion_id: String) -> bool:
	for animal in _vivas.values():
		if animal == null or not is_instance_valid(animal):
			continue
		if str(animal.get("definicion_id")) == definicion_id:
			var definicion = animal.get("definicion")
			if definicion != null and bool(definicion.domestico):
				return true
	return false

## Procesa una entidad doméstica sin mezclar su inventario con el del jugador.
## El lote es transaccional: si falta alimento o no caben los productos, no
## se consume nada.
func procesar_animal(animal: Node) -> Dictionary:
	if animal == null or not is_instance_valid(animal):
		return {"ok": false, "motivo": "animal_invalido", "productos": {}}
	var definicion = animal.get("definicion")
	if definicion == null or not bool(definicion.domestico):
		return {"ok": false, "motivo": "no_domestico", "productos": {}}
	var consume: Dictionary = definicion.consume
	var produce: Dictionary = definicion.produce
	if not Almacen.hay_todo(consume):
		return {"ok": false, "motivo": "falta_alimento", "productos": {}}
	if not _caben_productos(produce):
		return {"ok": false, "motivo": "almacen_lleno", "productos": {}}

	for id in consume:
		if not Almacen.retirar(str(id), int(consume[id])):
			return {"ok": false, "motivo": "cambio_concurrente", "productos": {}}
	var aceptados: Dictionary = {}
	for id in produce:
		var item_id := str(id)
		var cantidad := int(produce[id])
		var entro := Almacen.anadir(item_id, cantidad, "produccion_animal")
		if entro != cantidad:
			for rollback_id in aceptados:
				Almacen.retirar(str(rollback_id), int(aceptados[rollback_id]))
			for devolver_id in consume:
				Almacen.anadir(str(devolver_id), int(consume[devolver_id]), "rollback_animal")
			return {"ok": false, "motivo": "almacen_lleno", "productos": {}}
		aceptados[item_id] = cantidad
	produccion_diaria.emit(str(animal.get("definicion_id")), aceptados)
	return {"ok": true, "productos": aceptados}

func _caben_productos(productos: Dictionary) -> bool:
	if Almacen.capacidad_volumen <= 0.0:
		return true
	var volumen := 0.0
	for id in productos:
		var item: ItemData = BaseDeDatos.item(str(id))
		if item != null:
			volumen += item.volumen * int(productos[id])
	return Almacen.volumen_ocupado() + volumen <= Almacen.capacidad_volumen + 0.0001

func _procesar_nuevo_dia(_dia: int) -> void:
	for animal in _vivas.values():
		var resultado := procesar_animal(animal)
		if bool(resultado.get("ok", false)):
			anotar(animal)

func _al_salir(instancia: String) -> void:
	_vivas.erase(instancia)

func _serializar() -> Dictionary:
	return {"estados": _estados.duplicate(true)}

func _cargar(datos: Dictionary) -> void:
	_estados = (datos.get("estados", {}) as Dictionary).duplicate(true)
	for id in _vivas:
		var animal: Node = _vivas[id]
		if animal != null and is_instance_valid(animal) and _estados.has(id):
			animal.call("aplicar_estado", _estados[id])

func reiniciar() -> void:
	_estados.clear()
	_vivas.clear()
