extends Node
## AUTOLOAD: NpcsMundo
##
## Registro plano de los NPCs vivos. Las escenas se reconstruyen al arrancar;
## este nodo sólo conserva identidad, posición y rutina para Guardado.

signal npc_cambiado(instancia: String)

var _estados: Dictionary = {}
var _vivos: Dictionary = {}

func _ready() -> void:
	Guardado.registrar("npcs", _serializar, _cargar)

func registrar(npc: Node) -> bool:
	if npc == null:
		return false
	var identidad: Identidad = npc.get("identidad") as Identidad
	if identidad == null:
		return false
	var id := str(identidad.instancia)
	_vivos[id] = npc
	if _estados.has(id):
		npc.call("aplicar_estado", _estados[id])
	else:
		_estados[id] = npc.call("serializar")
	if not npc.tree_exiting.is_connected(_al_salir.bind(id)):
		npc.tree_exiting.connect(_al_salir.bind(id), CONNECT_ONE_SHOT)
	return true

func anotar(npc: Node) -> void:
	if npc == null:
		return
	var identidad: Identidad = npc.get("identidad") as Identidad
	if identidad == null or not _estados.has(identidad.instancia):
		return
	_estados[identidad.instancia] = npc.call("serializar")
	npc_cambiado.emit(identidad.instancia)

func estado(instancia: String) -> Dictionary:
	return (_estados.get(instancia, {}) as Dictionary).duplicate(true)

func _al_salir(instancia: String) -> void:
	_vivos.erase(instancia)

func _serializar() -> Dictionary:
	return {"estados": _estados.duplicate(true)}

func _cargar(datos: Dictionary) -> void:
	_estados = (datos.get("estados", {}) as Dictionary).duplicate(true)
	for id in _vivos:
		var npc: Node = _vivos[id]
		if npc != null and is_instance_valid(npc) and _estados.has(id):
			npc.call("aplicar_estado", _estados[id])

func reiniciar() -> void:
	_estados.clear()
	_vivos.clear()
