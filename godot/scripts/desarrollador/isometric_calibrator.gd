@tool
class_name IsometricCalibrator
extends Node2D
## Calibrador visual local del modo desarrollador.
## No cambia huella, transitabilidad ni colisiones: solo transforma el Sprite2D.

var target_sprite: Sprite2D = null
var huella_casillas: Vector2i = Vector2i.ONE
var mostrar_guia: bool = true
var mostrar_huella: bool = true
var mostrar_ancla: bool = true
var mostrar_caja_visual: bool = true

var ajuste_offset: Vector2 = Vector2.ZERO
var ajuste_escala: Vector2 = Vector2.ONE
var ajuste_skew: float = 0.0
var ajuste_rotacion: float = 0.0

var _base_offset := Vector2.ZERO
var _base_escala := Vector2.ONE
var _base_skew := 0.0
var _base_rotacion := 0.0

func configurar(sprite: Sprite2D, huella: Vector2i = Vector2i.ONE) -> void:
	target_sprite = sprite
	huella_casillas = Vector2i(maxi(1, huella.x), maxi(1, huella.y))
	_base_offset = sprite.offset
	_base_escala = sprite.scale
	_base_skew = sprite.skew
	_base_rotacion = sprite.rotation
	visible = true
	queue_redraw()

func configurar_con_base(sprite: Sprite2D, huella: Vector2i, base_offset: Vector2,
		base_escala: Vector2 = Vector2.ONE, base_skew: float = 0.0,
		base_rotacion: float = 0.0) -> void:
	target_sprite = sprite
	huella_casillas = Vector2i(maxi(1, huella.x), maxi(1, huella.y))
	_base_offset = base_offset
	_base_escala = base_escala
	_base_skew = base_skew
	_base_rotacion = base_rotacion
	visible = true
	queue_redraw()

func establecer_base(offset: Vector2, escala: Vector2, skew: float, rotacion: float) -> void:
	_base_offset = offset
	_base_escala = escala
	_base_skew = skew
	_base_rotacion = rotacion
	_aplicar()

func establecer_ajustes(offset: Vector2, escala: Vector2, skew: float, rotacion_grados: float) -> void:
	ajuste_offset = offset
	ajuste_escala = escala
	ajuste_skew = skew
	ajuste_rotacion = rotacion_grados
	_aplicar()

func restaurar() -> void:
	ajuste_offset = Vector2.ZERO
	ajuste_escala = Vector2.ONE
	ajuste_skew = 0.0
	ajuste_rotacion = 0.0
	_aplicar()

func estado() -> Dictionary:
	return {
		"offset": [ajuste_offset.x, ajuste_offset.y],
		"escala": [ajuste_escala.x, ajuste_escala.y],
		"skew": ajuste_skew,
		"rotacion": ajuste_rotacion,
	}

func _aplicar() -> void:
	if target_sprite == null or not is_instance_valid(target_sprite):
		return
	target_sprite.offset = _base_offset + ajuste_offset
	target_sprite.scale = Vector2(_base_escala.x * ajuste_escala.x, _base_escala.y * ajuste_escala.y)
	target_sprite.skew = _base_skew + deg_to_rad(ajuste_skew)
	target_sprite.rotation = _base_rotacion + deg_to_rad(ajuste_rotacion)
	queue_redraw()

func _draw() -> void:
	if target_sprite == null or not is_instance_valid(target_sprite):
		return
	if mostrar_guia:
		var guia := PackedVector2Array([
			Vector2(0.0, -Iso.MEDIO_Y),
			Vector2(Iso.MEDIO_X, 0.0),
			Vector2(0.0, Iso.MEDIO_Y),
			Vector2(-Iso.MEDIO_X, 0.0),
			Vector2(0.0, -Iso.MEDIO_Y),
		])
		draw_polyline(guia, Color("5cb2b5", 0.9), 1.0)
	if mostrar_huella:
		var huella := _poligono_huella()
		draw_polyline(huella, Color("f5c051", 0.9), 2.0)
	if mostrar_ancla:
		draw_line(Vector2(-10, 0), Vector2(10, 0), Color.WHITE, 1.0)
		draw_line(Vector2(0, -10), Vector2(0, 10), Color.WHITE, 1.0)
		draw_circle(Vector2.ZERO, 3.0, Color("f5c051"))
	if mostrar_caja_visual and target_sprite.texture != null:
		var local := target_sprite.get_rect()
		var transform := get_global_transform().affine_inverse() * target_sprite.get_global_transform()
		var esquinas := PackedVector2Array([
			transform * local.position,
			transform * Vector2(local.end.x, local.position.y),
			transform * local.end,
			transform * Vector2(local.position.x, local.end.y),
			transform * local.position,
		])
		draw_polyline(esquinas, Color("e87a41", 0.9), 2.0)

func _poligono_huella() -> PackedVector2Array:
	var ancho := maxi(1, huella_casillas.x)
	var alto := maxi(1, huella_casillas.y)
	return PackedVector2Array([
		Vector2(0.0, -Iso.MEDIO_Y),
		Vector2(Iso.MEDIO_X * ancho, Iso.MEDIO_Y * (ancho - 1)),
		Vector2(Iso.MEDIO_X * (ancho - alto), Iso.MEDIO_Y * (ancho + alto - 1)),
		Vector2(-Iso.MEDIO_X * alto, Iso.MEDIO_Y * (alto - 1)),
		Vector2(0.0, -Iso.MEDIO_Y),
	])
