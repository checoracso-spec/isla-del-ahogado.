class_name PreviewColocacion
extends Node2D
## PROTOTIPO — Modo Desarrollador de Interiores (Fase 2, ampliado en Fase 5
## para cofres). Dibuja dónde caería un mueble y si esa posición es válida.
## No coloca nada: es puramente visual, vive solo dentro de
## comparador_herreria.tscn.

var _sprite: Sprite2D = null
var _clave_actual := ""

const COLOR_VALIDO := Color(0.4, 1.0, 0.55, 0.55)
const COLOR_INVALIDO := Color(1.0, 0.35, 0.35, 0.55)

func _ready() -> void:
	visible = false

## Cambia qué asset se previsualiza. Se llama al cambiar de mueble
## seleccionado, no en cada frame.
## Los cofres no usan "asset" sino "asset_cerrado"/"asset_abierto" (estado
## visual, no una sola clave) — se previsualiza con el cerrado.
func configurar(mueble: Dictionary) -> void:
	var clave := str(mueble.get("asset", ""))
	if clave == "":
		clave = str(mueble.get("asset_cerrado", ""))
	if clave == "" or not Assets.existe(clave):
		visible = false
		return
	if clave != _clave_actual:
		if _sprite != null:
			_sprite.queue_free()
		_sprite = Assets.sprite(clave)
		add_child(_sprite)
		_clave_actual = clave
	visible = true

## Se llama cada frame con la casilla actual bajo el cursor.
func actualizar(casilla: Vector2i, huella: Vector2i, valido: bool) -> void:
	if not visible or _sprite == null:
		return
	position = _punto_anclaje(casilla, huella)
	_sprite.modulate = COLOR_VALIDO if valido else COLOR_INVALIDO

## Misma fórmula que InteriorEscena._punto_anclaje(): huella 1×1 usa el
## centro de la casilla, huellas más grandes anclan por la esquina de apoyo.
## No se importa esa función privada a propósito; se reimplementa aquí en
## dos líneas para no tocar interior_escena.gd en esta fase.
func _punto_anclaje(origen: Vector2i, huella: Vector2i) -> Vector2:
	if huella == Vector2i.ONE:
		return Iso.centro_v(origen)
	var apoyo := origen + huella - Vector2i.ONE
	return Iso.apoyo(apoyo.x, apoyo.y)
