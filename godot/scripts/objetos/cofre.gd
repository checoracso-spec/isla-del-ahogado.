class_name Cofre
extends Interactuable
## Un cofre. Reutiliza `Interactuable` para que lo detecte el jugador e
## `Inventario` para lo que lleva dentro; no inventa nada propio.
##
## Ojo con una cosa: NO guarda su inventario en una variable. Se lo pide a
## `Contenedores` cada vez. Si lo cacheara, al cargar una partida se quedaría
## apuntando al inventario viejo y enseñaría objetos que ya no existen.

signal abierto(cofre: Cofre)

var identidad: Identidad
var contenido_inicial: Dictionary = {}
var zona_id: String = ""
var casilla_interior: Vector2i = Vector2i.ZERO
var asset_cerrado: String = ""
var asset_abierto: String = ""
var _sprite: Sprite2D
var _abierto_visual := false

func _ready() -> void:
	super()
	alcance = 1.5
	_montar_sprite()

func _montar_sprite() -> void:
	if asset_cerrado == "" or not Assets.existe(asset_cerrado):
		return
	_sprite = Assets.sprite(asset_cerrado)
	_sprite.name = "Visual"
	add_child(_sprite)
	queue_redraw()

func _actualizar_sprite() -> void:
	if _sprite == null:
		return
	var clave := asset_abierto if _abierto_visual and Assets.existe(asset_abierto) \
		else asset_cerrado
	_sprite.texture = Assets.textura(clave)
	_sprite.offset = -Assets.pivote(clave)

func casilla() -> Vector2i:
	return casilla_interior

func inventario() -> Inventario:
	if identidad == null:
		return null
	return Contenedores.inventario_de(identidad, contenido_inicial, zona_id)

func texto_accion() -> String:
	var inv := inventario()
	if inv != null and inv.esta_vacio():
		return "Cofre vacío"
	return "Abrir cofre"

func disponible(_quien: Node) -> bool:
	return identidad != null

func interactuar(_quien: Node) -> void:
	# Se asegura de que el inventario existe antes de que nadie lo mire.
	var _inv := inventario()
	_abierto_visual = true
	_actualizar_sprite()
	abierto.emit(self)

func _draw() -> void:
	if _sprite != null:
		return
	var vacio := inventario() != null and inventario().esta_vacio()
	var cuerpo := Color("6b4a24") if not vacio else Color("54402a")
	var herraje := Color("c9a227") if not vacio else Color("7d6f4f")
	var c := Vector2.ZERO
	var alto := Vector2(0, -26.0)
	var e := c + Vector2(Iso.MEDIO_X * 0.45, 0)
	var s := c + Vector2(0, Iso.MEDIO_Y * 0.45)
	var o := c + Vector2(-Iso.MEDIO_X * 0.45, 0)
	var n := c + Vector2(0, -Iso.MEDIO_Y * 0.45)
	draw_colored_polygon(PackedVector2Array([o + alto, s + alto, s, o]), cuerpo.darkened(0.28))
	draw_colored_polygon(PackedVector2Array([s + alto, e + alto, e, s]), cuerpo.darkened(0.12))
	draw_colored_polygon(PackedVector2Array([n + alto, e + alto, s + alto, o + alto]), cuerpo)
	draw_line(o + alto, e + alto, herraje, 2.5)
	draw_line(n + alto, s + alto, herraje, 2.5)
