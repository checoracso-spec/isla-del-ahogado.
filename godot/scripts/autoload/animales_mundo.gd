extends Node
## AUTOLOAD: AnimalesMundo
##
## Registro de estado plano de animales vivos. La entidad Node2D es temporal;
## esta tabla conserva identidad, posición y estado para guardar/cargar sin
## serializar referencias al árbol.

signal animal_cambiado(instancia: String)

var _estados: Dictionary = {}
var _vivas: Dictionary = {}

func _ready() -> void:
	Guardado.registrar("animales_mundo", _serializar, _cargar)

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
