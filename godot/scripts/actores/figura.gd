class_name Figura
extends RefCounted
## El muñeco dibujado por código, en un solo sitio.
##
## Marcador de posición deliberado hasta que llegue el pixel art. Lo usan el
## jugador, la tripulación y —más adelante— los NPCs, para no tener tres copias
## del mismo dibujo. Cuando haya sprites, se sustituye la llamada a `dibujar`
## por un AnimatedSprite2D y esta clase desaparece sin tocar la lógica.

## `op` admite: ropa, panuelo, piel, altura, fase, mirando_derecha, sombrero.
static func dibujar(c: CanvasItem, op: Dictionary) -> void:
	var h: float = op.get("altura", 92.0)
	var fase: float = op.get("fase", 0.0)
	var andando: bool = op.get("andando", false)
	var lado := 1.0 if op.get("mirando_derecha", true) else -1.0
	var tono: Color = op.get("ropa", Color("8c3b2f"))
	var panuelo: Color = op.get("panuelo", Color("c9a227"))
	var piel: Color = op.get("piel", Color("c98f63"))
	var sombrero: bool = op.get("sombrero", false)

	var vaiven := sin(fase) if andando else 0.0
	var bote := absf(vaiven) * 2.4
	var pies := Vector2(0, -bote)
	var oscuro := tono.darkened(0.35)

	_elipse(c, Vector2.ZERO, Vector2(13, 6.5),
		GlobalColors.con_alpha("vacio_abismal", 0.28))

	var sep := vaiven * 4.0
	_pierna(c, pies + Vector2(-3 + sep, 0), h)
	_pierna(c, pies + Vector2(3 - sep, 0), h)

	var torso_alto := h * 0.42
	var torso_y := pies.y - h * 0.34
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(-9.5, torso_y), Vector2(9.5, torso_y),
		Vector2(7.5, torso_y + torso_alto), Vector2(-7.5, torso_y + torso_alto),
	]), tono)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(lado * 1.5, torso_y), Vector2(lado * 9.5, torso_y),
		Vector2(lado * 7.5, torso_y + torso_alto), Vector2(lado * 2.0, torso_y + torso_alto),
	]), oscuro)
	c.draw_rect(Rect2(-8.5, torso_y + torso_alto - 7, 17, 6), panuelo)

	var brazo := vaiven * 5.0
	_brazo(c, Vector2(-9, torso_y + 6), brazo, tono.darkened(0.15), piel)
	_brazo(c, Vector2(9, torso_y + 6), -brazo, tono.darkened(0.15), piel)

	var cabeza := Vector2(lado * 1.0, torso_y - 9.0)
	c.draw_circle(cabeza, 8.0, piel)

	if sombrero:
		# Tricornio: ala ancha y copa. Distingue al jugador de la tripulación.
		c.draw_colored_polygon(PackedVector2Array([
			cabeza + Vector2(-14, -4), cabeza + Vector2(14, -4),
			cabeza + Vector2(9, -9), cabeza + Vector2(-9, -9),
		]), panuelo.darkened(0.45))
		c.draw_colored_polygon(PackedVector2Array([
			cabeza + Vector2(-8, -8), cabeza + Vector2(8, -8),
			cabeza + Vector2(4, -15), cabeza + Vector2(-4, -15),
		]), panuelo.darkened(0.3))
	else:
		c.draw_colored_polygon(PackedVector2Array([
			cabeza + Vector2(-8.5, -2.5), cabeza + Vector2(8.5, -2.5),
			cabeza + Vector2(7.0, -8.5), cabeza + Vector2(-7.0, -8.5),
		]), panuelo)
		c.draw_colored_polygon(PackedVector2Array([
			cabeza + Vector2(-lado * 7.0, -3.0), cabeza + Vector2(-lado * 13.0, 1.0),
			cabeza + Vector2(-lado * 7.0, 2.0),
		]), panuelo.darkened(0.15))

	c.draw_circle(cabeza + Vector2(lado * 3.2, 0.5), 1.3, Color(0.1, 0.08, 0.07))

static func _pierna(c: CanvasItem, base: Vector2, h: float) -> void:
	var alto := h * 0.26
	c.draw_colored_polygon(PackedVector2Array([
		base + Vector2(-3.2, -alto), base + Vector2(3.2, -alto),
		base + Vector2(2.6, -2.0), base + Vector2(-2.6, -2.0),
	]), Color("3b3129"))
	c.draw_rect(Rect2(base.x - 4.0, base.y - 3.0, 8.0, 3.2), Color("241d18"))

static func _brazo(c: CanvasItem, hombro: Vector2, balanceo: float,
		color: Color, piel: Color) -> void:
	var mano := hombro + Vector2(balanceo * 0.5, 16.0)
	c.draw_line(hombro, mano, color, 5.0)
	c.draw_circle(mano, 2.6, piel)

static func _elipse(c: CanvasItem, centro: Vector2, radios: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(centro + Vector2(cos(a) * radios.x, sin(a) * radios.y))
	c.draw_colored_polygon(pts, color)
