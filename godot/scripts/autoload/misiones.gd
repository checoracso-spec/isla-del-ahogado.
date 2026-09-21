extends Node
## AUTOLOAD: Misiones
##
## Estado mínimo de misiones. El contenido y las interacciones llegarán en
## tareas posteriores; aquí sólo viven las transiciones y su sección de
## guardado, usando el límite existente de Guardado.

enum QuestState { AVAILABLE, ACCEPTED, OBJECTIVE_COMPLETE, TURNED_IN }

signal estado_cambiado(mision_id: String, estado: int)

var _estados: Dictionary = {}

func _ready() -> void:
	Guardado.registrar("misiones", _serializar, _cargar)

func registrar(mision_id: String) -> bool:
	var id := mision_id.strip_edges()
	if id.is_empty() or _estados.has(id):
		return false
	_estados[id] = QuestState.AVAILABLE
	return true

func ids() -> Array[String]:
	var resultado: Array[String] = []
	for id in _estados:
		resultado.append(str(id))
	resultado.sort()
	return resultado

func estado(mision_id: String) -> int:
	return int(_estados.get(mision_id, QuestState.AVAILABLE))

func aceptar(mision_id: String) -> bool:
	return _transicionar(mision_id, QuestState.AVAILABLE, QuestState.ACCEPTED)

func completar_objetivo(mision_id: String) -> bool:
	return _transicionar(mision_id, QuestState.ACCEPTED, QuestState.OBJECTIVE_COMPLETE)

func entregar(mision_id: String) -> bool:
	return _transicionar(mision_id, QuestState.OBJECTIVE_COMPLETE, QuestState.TURNED_IN)

func reiniciar() -> void:
	_estados.clear()

func _transicionar(mision_id: String, esperado: int, siguiente: int) -> bool:
	if not _estados.has(mision_id) or int(_estados[mision_id]) != esperado:
		return false
	_estados[mision_id] = siguiente
	estado_cambiado.emit(mision_id, siguiente)
	return true

func _serializar() -> Dictionary:
	return {"estados": _estados.duplicate(true)}

func _cargar(datos: Dictionary) -> void:
	_estados.clear()
	var recibidos: Variant = datos.get("estados", {})
	if not recibidos is Dictionary:
		return
	for id in recibidos:
		var estado_recibido := int(recibidos[id])
		if str(id).strip_edges().is_empty():
			continue
		if estado_recibido < QuestState.AVAILABLE or estado_recibido > QuestState.TURNED_IN:
			continue
		_estados[str(id)] = estado_recibido
