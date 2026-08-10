class_name ZonaChunk
extends Node2D

## Contenedor de una porción de zona. El contenido concreto puede llegar
## después; por ahora ofrece ciclo de vida, límites e identidad de chunk.

var coordenada: Vector2i = Vector2i.ZERO
var limites_chunk: Rect2i = Rect2i()
var activo: bool = true
var contenido: Array[Node] = []

func montar(p_coordenada: Vector2i, p_limites: Rect2i) -> void:
	coordenada = p_coordenada
	limites_chunk = p_limites
	name = "Chunk_%d_%d" % [coordenada.x, coordenada.y]

func activar() -> void:
	activo = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_aplicar_estado_contenido()

func desactivar() -> void:
	activo = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_aplicar_estado_contenido()

func registrar_contenido(nodo: Node) -> void:
	if nodo == null or contenido.has(nodo):
		return
	contenido.append(nodo)
	_aplicar_estado(nodo)

func limpiar_contenido() -> void:
	contenido.clear()

func _aplicar_estado_contenido() -> void:
	for nodo in contenido:
		_aplicar_estado(nodo)

func _aplicar_estado(nodo: Node) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	nodo.process_mode = Node.PROCESS_MODE_INHERIT if activo \
		else Node.PROCESS_MODE_DISABLED
	if nodo is CanvasItem:
		(nodo as CanvasItem).visible = activo

func serializar() -> Dictionary:
	return {"x": coordenada.x, "y": coordenada.y, "activo": activo}

func cargar(datos: Dictionary) -> void:
	activo = bool(datos.get("activo", true))
	if activo:
		activar()
	else:
		desactivar()
