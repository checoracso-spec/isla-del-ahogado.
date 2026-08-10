class_name ZonaChunk
extends Node2D

## Contenedor de una porción de zona. El contenido concreto puede llegar
## después; por ahora ofrece ciclo de vida, límites e identidad de chunk.

var coordenada: Vector2i = Vector2i.ZERO
var limites_chunk: Rect2i = Rect2i()
var activo: bool = true

func montar(p_coordenada: Vector2i, p_limites: Rect2i) -> void:
	coordenada = p_coordenada
	limites_chunk = p_limites
	name = "Chunk_%d_%d" % [coordenada.x, coordenada.y]

func activar() -> void:
	activo = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT

func desactivar() -> void:
	activo = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func serializar() -> Dictionary:
	return {"x": coordenada.x, "y": coordenada.y, "activo": activo}

func cargar(datos: Dictionary) -> void:
	activo = bool(datos.get("activo", true))
	if activo:
		activar()
	else:
		desactivar()
