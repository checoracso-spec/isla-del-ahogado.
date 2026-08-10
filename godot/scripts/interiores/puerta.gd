class_name Puerta
extends Interactuable
## Un punto de paso entre dos zonas.
##
## Sabe de dónde a dónde lleva y nada más. NO abre el interior, NO mueve al
## jugador y NO toca la cámara: se limita a avisar de que la han cruzado. De
## ahí en adelante es cosa de `Interiores`.
##
## Esa separación es la que permitirá reutilizarla tal cual para la escotilla
## de un barco o la boca de una cueva.

signal atravesada(puerta: Puerta)

enum Sentido { ENTRAR, SALIR }

var identidad: Identidad                 ## la de esta puerta concreta
var sentido: int = Sentido.ENTRAR
var edificio_definicion: String = ""     ## "taberna" — qué es
var edificio_instancia: String = ""      ## "edificio_0007" — cuál es
var interior_id: String = ""             ## a qué interior lleva
var casilla_exterior: Vector2i           ## dónde escupe al salir
var casilla_propia: Vector2i             ## dónde está esta puerta
var _sprite: Sprite2D = null             ## sólo si el edificio trae arte de kit

## Si el edificio tiene arte en el manifiesto, la puerta usa su sprite en vez
## del rombo dibujado por código. Si la clave no existe, se queda con el rombo:
## una puerta sin felpudo sigue funcionando.
func usar_asset(clave: String) -> void:
	if not Assets.existe(clave):
		return
	_sprite = Assets.sprite(clave)
	_sprite.name = "Felpudo"
	add_child(_sprite)
	queue_redraw()

func usa_asset() -> bool:
	return _sprite != null

func _ready() -> void:
	super()
	alcance = 1.6

func texto_accion() -> String:
	if sentido == Sentido.SALIR:
		return "Salir"
	var e: EdificioData = BaseDeDatos.edificio(edificio_definicion)
	return "Entrar en %s" % e.nombre if e != null else "Entrar"

func disponible(_quien: Node) -> bool:
	return interior_id != "" or sentido == Sentido.SALIR

func interactuar(_quien: Node) -> void:
	atravesada.emit(self)

func casilla() -> Vector2i:
	return casilla_propia

## Marca visible mientras no haya arte: un arco oscuro en el suelo.
func _draw() -> void:
	if _sprite != null:
		return                          ## ya tiene felpudo de verdad
	var color := Color(0.13, 0.10, 0.08, 0.85)
	var pts := PackedVector2Array([
		Vector2(0, -Iso.MEDIO_Y * 0.55),
		Vector2(Iso.MEDIO_X * 0.5, 0),
		Vector2(0, Iso.MEDIO_Y * 0.55),
		Vector2(-Iso.MEDIO_X * 0.5, 0),
	])
	draw_colored_polygon(pts, color)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.85, 0.72, 0.42, 0.9), 2.0)
