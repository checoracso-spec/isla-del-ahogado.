class_name MuebleVisual
extends Node2D
## Sustituto visual limpio para un asset técnico mientras llega el arte final.
## No contiene colisión ni interacción: esas responsabilidades siguen en el
## nodo padre y en la definición del interior.

var tipo: String = "mueble"
var huella: Vector2i = Vector2i.ONE

func configurar(p_tipo: String, p_huella: Vector2i) -> void:
	tipo = p_tipo
	huella = p_huella
	queue_redraw()

func _draw() -> void:
	var desplazamiento := Vector2.ZERO
	if huella != Vector2i.ONE:
		desplazamiento = Vector2(-64.0 * float(huella.x - 1), -32.0 * float(huella.x - 1))
	var c := desplazamiento
	match tipo:
		"banco_trabajo", "mesa": _dibujar_mesa(c)
		"horno": _dibujar_horno(c)
		"yunque": _dibujar_yunque(c)
		"estanteria", "herramientas", "panoplia": _dibujar_estanteria(c)
		"carbon": _dibujar_carbon(c)
		"barril": _dibujar_barril(c)
		_: _dibujar_mueble(c)

func _rombo(c: Vector2, color: Color, escala: float = 0.72) -> void:
	var hx := Iso.MEDIO_X * escala
	var hy := Iso.MEDIO_Y * escala
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -hy), c + Vector2(hx, 0),
		c + Vector2(0, hy), c + Vector2(-hx, 0)]), color)

func _dibujar_mesa(c: Vector2) -> void:
	_rombo(c + Vector2(0, -13), Color("8f5c3b"), 0.75)
	var base := c + Vector2(0, -8)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-35, 0), base + Vector2(0, 18),
		base + Vector2(35, 0), base + Vector2(0, -18)]), Color("663b2a"))
	draw_line(base + Vector2(-22, 4), base + Vector2(-22, 19), Color("42241c"), 4)
	draw_line(base + Vector2(22, 4), base + Vector2(22, 19), Color("42241c"), 4)

func _dibujar_horno(c: Vector2) -> void:
	var cuerpo := Rect2(c + Vector2(-25, -62), Vector2(50, 54))
	draw_rect(cuerpo, Color("5e5e73"))
	draw_rect(Rect2(c + Vector2(-18, -43), Vector2(36, 28)), Color("252536"))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-13, -20), c + Vector2(13, -20),
		c + Vector2(8, -30), c + Vector2(-8, -30)]), Color("e87a41"))
	draw_line(c + Vector2(-23, -62), c + Vector2(23, -62), Color("8b8b9e"), 3)

func _dibujar_yunque(c: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-27, -45), c + Vector2(23, -45),
		c + Vector2(13, -31), c + Vector2(-18, -31)]), Color("8b8b9e"))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-17, -31), c + Vector2(13, -31),
		c + Vector2(7, -8), c + Vector2(-10, -8)]), Color("5e5e73"))
	draw_line(c + Vector2(-22, -45), c + Vector2(18, -45), Color("c2c2d1"), 2)

func _dibujar_estanteria(c: Vector2) -> void:
	draw_rect(Rect2(c + Vector2(-25, -84), Vector2(50, 72)), Color("42241c"))
	for y in [-68, -47, -26]:
		draw_line(c + Vector2(-21, y), c + Vector2(21, y), Color("c48d5f"), 3)
	for x in [-14, 0, 14]:
		draw_circle(c + Vector2(x, -57), 4, Color("8f5c3b"))
		draw_circle(c + Vector2(x, -36), 4, Color("8b8b9e"))

func _dibujar_carbon(c: Vector2) -> void:
	_rombo(c + Vector2(0, -7), Color("291814"), 0.68)
	for punto in [Vector2(-15, -20), Vector2(0, -27), Vector2(15, -19), Vector2(-4, -12)]:
		draw_circle(c + punto, 7, Color("3d3d52"))

func _dibujar_barril(c: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-18, -44), c + Vector2(18, -44),
		c + Vector2(21, -12), c + Vector2(-21, -12)]), Color("663b2a"))
	_dibujar_ellipse(c + Vector2(0, -44), 18, 7, Color("c48d5f"))
	draw_line(c + Vector2(-18, -35), c + Vector2(18, -35), Color("42241c"), 3)
	draw_line(c + Vector2(-19, -20), c + Vector2(19, -20), Color("42241c"), 3)

func _dibujar_mueble(c: Vector2) -> void:
	_rombo(c, Color("663b2a"), 0.65)
	draw_rect(Rect2(c + Vector2(-20, -34), Vector2(40, 28)), Color("8f5c3b"))

func _dibujar_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var puntos := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		puntos.append(center + Vector2(cos(a) * radius_x, sin(a) * radius_y))
	draw_colored_polygon(puntos, color)
