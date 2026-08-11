class_name ArteBase
extends Node2D
## Capa visual base de un interior.
## Dibuja el respaldo antes que sus hijos, para que los tiles transparentes
## conserven sus esquinas limpias sin dejar juntas abiertas.

var respaldo_polygon: PackedVector2Array = PackedVector2Array()
var respaldo_color: Color = Color.TRANSPARENT
var borde_color: Color = Color.TRANSPARENT

func configurar_respaldo(polygon: PackedVector2Array, color: Color) -> void:
	respaldo_polygon = polygon
	respaldo_color = color
	borde_color = Color("3d3d52")
	queue_redraw()

func _draw() -> void:
	if respaldo_polygon.size() >= 3 and respaldo_color.a > 0.0:
		draw_colored_polygon(respaldo_polygon, respaldo_color)
		# Un borde discreto une visualmente el perímetro sin convertirse en una
		# pared sólida: las colisiones siguen viniendo de TransitableRejilla.
		var borde := respaldo_polygon.duplicate()
		borde.append(respaldo_polygon[0])
		draw_polyline(borde, borde_color, 10.0, true)
