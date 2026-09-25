extends Node
## AUTOLOAD: Misiones
##
## Estado mínimo de misiones. El contenido y las interacciones llegarán en
## tareas posteriores; aquí sólo viven las transiciones y su sección de
## guardado, usando el límite existente de Guardado.

enum QuestState { AVAILABLE, ACCEPTED, OBJECTIVE_COMPLETE, TURNED_IN }

signal estado_cambiado(mision_id: String, estado: int)

var _estados: Dictionary = {}
var _objetivos: Dictionary = {}

func _ready() -> void:
	Guardado.registrar("misiones", _serializar, _cargar)
	Bolsa.objetos_cambiados.connect(_al_cambiar_objetos)

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

func puede_aceptar(mision_id: String) -> bool:
	if not _estados.has(mision_id) or estado(mision_id) != QuestState.AVAILABLE:
		return false
	var definicion: MisionData = BaseDeDatos.mision(mision_id)
	if definicion == null or definicion.requisito_mision_id.is_empty():
		return true
	var requisito_id := definicion.requisito_mision_id
	return _estados.has(requisito_id) and estado(requisito_id) == QuestState.TURNED_IN

func aceptar(mision_id: String) -> bool:
	if not puede_aceptar(mision_id):
		return false
	var aceptada := _transicionar(mision_id, QuestState.AVAILABLE, QuestState.ACCEPTED)
	if aceptada:
		_evaluar_objetivo(mision_id)
	return aceptada

## Registra el requisito mínimo de una misión: tener una cantidad de un ítem.
## La fuente del mundo sólo entrega el ítem a Inventario; esta frontera se
## limita a observar Bolsa y traducirlo a la transición de la misión.
func registrar_objetivo_item(mision_id: String, item_id: String,
		cantidad_requerida: int = 1) -> bool:
	if not _estados.has(mision_id) or item_id.strip_edges().is_empty() \
			or cantidad_requerida <= 0 or BaseDeDatos.item(item_id) == null:
		return false
	_objetivos[mision_id] = {
		"tipo": "item",
		"item_id": item_id,
		"cantidad": cantidad_requerida,
	}
	_evaluar_objetivo(mision_id)
	return true

func objetivo_item(mision_id: String) -> Dictionary:
	return (_objetivos.get(mision_id, {}) as Dictionary).duplicate(true)

func completar_objetivo(mision_id: String) -> bool:
	return _transicionar(mision_id, QuestState.ACCEPTED, QuestState.OBJECTIVE_COMPLETE)

func entregar(mision_id: String) -> bool:
	return _transicionar(mision_id, QuestState.OBJECTIVE_COMPLETE, QuestState.TURNED_IN)

func reiniciar() -> void:
	_estados.clear()
	_objetivos.clear()

func _transicionar(mision_id: String, esperado: int, siguiente: int) -> bool:
	if not _estados.has(mision_id) or int(_estados[mision_id]) != esperado:
		return false
	_estados[mision_id] = siguiente
	estado_cambiado.emit(mision_id, siguiente)
	return true

func _serializar() -> Dictionary:
	return {
		"estados": _estados.duplicate(true),
		"objetivos": _objetivos.duplicate(true),
	}

func _cargar(datos: Dictionary) -> void:
	_estados.clear()
	_objetivos.clear()
	var recibidos: Variant = datos.get("estados", {})
	if recibidos is Dictionary:
		for id in recibidos:
			var estado_recibido := int(recibidos[id])
			if str(id).strip_edges().is_empty():
				continue
			if estado_recibido < QuestState.AVAILABLE or estado_recibido > QuestState.TURNED_IN:
				continue
			_estados[str(id)] = estado_recibido

	var objetivos_recibidos: Variant = datos.get("objetivos", {})
	if not objetivos_recibidos is Dictionary:
		return
	for id in objetivos_recibidos:
		if not _estados.has(str(id)) or not objetivos_recibidos[id] is Dictionary:
			continue
		var objetivo: Dictionary = objetivos_recibidos[id]
		var item_id := str(objetivo.get("item_id", ""))
		var cantidad := int(objetivo.get("cantidad", 0))
		if objetivo.get("tipo", "item") != "item" \
				or item_id.is_empty() or cantidad <= 0 \
				or BaseDeDatos.item(item_id) == null:
			continue
		_objetivos[str(id)] = {
			"tipo": "item",
			"item_id": item_id,
			"cantidad": cantidad,
		}

func _al_cambiar_objetos() -> void:
	for mision_id in _objetivos:
		_evaluar_objetivo(str(mision_id))

func _evaluar_objetivo(mision_id: String) -> void:
	if estado(mision_id) != QuestState.ACCEPTED:
		return
	var objetivo: Dictionary = _objetivos.get(mision_id, {})
	if objetivo.get("tipo", "") != "item":
		return
	var item_id := str(objetivo.get("item_id", ""))
	var cantidad := int(objetivo.get("cantidad", 0))
	if item_id.is_empty() or cantidad <= 0:
		return
	if Bolsa.mochila.cantidad(item_id) >= cantidad:
		completar_objetivo(mision_id)
