class_name ArteBase
extends Node2D
## Capa visual base de un interior.
## Dibuja el suelo y su zócalo antes que sus hijos.

var respaldo_polygon: PackedVector2Array = PackedVector2Array()
var respaldo_color: Color = Color.TRANSPARENT
var borde_color: Color = Color.TRANSPARENT
var borde_polygon: PackedVector2Array = PackedVector2Array()
var borde_grosor: float = 0.0

func configurar_respaldo(polygon: PackedVector2Array, color: Color) -> void:
	respaldo_polygon = polygon
	respaldo_color = color
	borde_color = Color("3d3d52")
	queue_redraw()

func configurar_borde(polygon: PackedVector2Array, grosor: float = 18.0) -> void:
	borde_polygon = polygon
	borde_grosor = grosor
	queue_redraw()

func _draw() -> void:
	if respaldo_polygon.size() >= 3 and respaldo_color.a > 0.0:
		draw_colored_polygon(respaldo_polygon, respaldo_color)
		var borde := respaldo_polygon.duplicate()
		borde.append(respaldo_polygon[0])
		draw_polyline(borde, borde_color, 10.0, true)
	if borde_polygon.size() >= 4 and borde_grosor > 0.0:
		var desplazamiento := Vector2(0.0, borde_grosor)
		# Solo las dos aristas abiertas del frente reciben zocalo visible.
		# Se dibuja despues del suelo para que la fascia quede visible.
		draw_colored_polygon(PackedVector2Array([
			borde_polygon[1], borde_polygon[2], borde_polygon[2] + desplazamiento,
			borde_polygon[1] + desplazamiento
		]), Color("252536"))
		draw_colored_polygon(PackedVector2Array([
			borde_polygon[2], borde_polygon[3], borde_polygon[3] + desplazamiento,
			borde_polygon[2] + desplazamiento
		]), Color("303044"))
