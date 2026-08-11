class_name ArteBase
extends Node2D
## Capa visual base de un interior.
## Dibuja el respaldo antes que sus hijos, para que los tiles transparentes
## conserven sus esquinas limpias sin dejar juntas abiertas.

var respaldo_polygon: PackedVector2Array = PackedVector2Array()
var respaldo_color: Color = Color.TRANSPARENT

func configurar_respaldo(polygon: PackedVector2Array, color: Color) -> void:
	respaldo_polygon = polygon
	respaldo_color = color
	queue_redraw()

func _draw() -> void:
	if respaldo_polygon.size() >= 3 and respaldo_color.a > 0.0:
		draw_colored_polygon(respaldo_polygon, respaldo_color)
