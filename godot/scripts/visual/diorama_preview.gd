extends Sprite2D
## Visor opcional de una pieza del catálogo externo.
##
## Es exclusivamente visual: no añade colisiones, transitabilidad,
## interacción, inventario ni estado de guardado.

@export var clave_catalogo: String = ""
@export var escala_visual: float = 1.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture = DioramasExternos.textura(clave_catalogo)
	if texture == null:
		push_warning("DioramaPreview: clave externa no disponible '%s'" % clave_catalogo)
		return
	scale = Vector2.ONE * escala_visual
