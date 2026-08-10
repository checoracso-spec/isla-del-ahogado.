class_name CamaraIsla
extends Camera2D
## Cámara del mapa.
##
## Dos modos: LIBRE (arrastrar y teclas, como hasta ahora) y SEGUIR (pegada al
## jugador). Cambia sola al primer movimiento del ratón o al asignar objetivo,
## así que se puede pasear la vista y volver al personaje sin botones.
##
## Los límites se fijan por CASILLAS, no por píxeles: así valen igual para la
## isla de 60×60 que para el interior de una casa de 8×8, sin cuentas a mano
## en cada sitio.

const VELOCIDAD := 900.0
const ZOOM_MIN := 0.18
const ZOOM_MAX := 1.30
const SUAVIZADO := 7.0

## Niveles del modo pixel: sólo escalas limpias. A 1.0 cada píxel de arte es un
## píxel de pantalla; a 0.5, cada bloque lógico de 2×2 ocupa uno. Cualquier
## valor intermedio reparte los píxeles de forma desigual y la imagen tiembla
## al moverse, que es lo que delata al pixel art mal montado.
const NIVELES_PIXEL := [0.5, 1.0]

enum Modo { LIBRE, SEGUIR }

var modo: int = Modo.LIBRE
var objetivo: Node2D = null

## Modo del kit: zoom en escalones y cámara cuadrada a píxeles enteros.
## Apagado por defecto porque el arte fotorrealista que todavía queda se ve
## mejor con zoom continuo.
var modo_pixel: bool = false:
	set(v):
		modo_pixel = v
		if v:
			zoom_a_nivel(_nivel_mas_cercano())

var _arrastrando := false

func _ready() -> void:
	zoom = Vector2(0.55, 0.55)

# ---------------------------------------------------------------------------
# ZOOM DISCRETO
# ---------------------------------------------------------------------------

func nivel_actual() -> int:
	return _nivel_mas_cercano()

func zoom_a_nivel(indice: int) -> void:
	var i := clampi(indice, 0, NIVELES_PIXEL.size() - 1)
	var z: float = NIVELES_PIXEL[i]
	zoom = Vector2(z, z)

func _nivel_mas_cercano() -> int:
	var mejor := 0
	var dist := INF
	for i in NIVELES_PIXEL.size():
		var d: float = absf(float(NIVELES_PIXEL[i]) - zoom.x)
		if d < dist:
			dist = d
			mejor = i
	return mejor

## Para que un píxel de arte caiga siempre en un píxel de pantalla, la cámara
## no puede pararse en medio de uno. El paso depende del zoom: a 1.0 se
## redondea a la unidad; a 0.5, de dos en dos.
func _cuadrar_a_pixel() -> void:
	var paso := 1.0 / maxf(0.0001, zoom.x)
	position = (position / paso).round() * paso

## Al asignar objetivo la cámara se engancha; con null vuelve a modo libre.
func seguir(a_quien: Node2D) -> void:
	objetivo = a_quien
	modo = Modo.SEGUIR if a_quien != null else Modo.LIBRE
	if objetivo != null:
		position = objetivo.position

func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton:
		match evento.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_acercar(1.12)
			MOUSE_BUTTON_WHEEL_DOWN:
				_acercar(1.0 / 1.12)
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				_arrastrando = evento.pressed
				if evento.pressed:
					modo = Modo.LIBRE
	elif evento is InputEventMouseMotion and _arrastrando:
		position -= evento.relative / zoom

func _acercar(factor: float) -> void:
	if modo_pixel:
		# En modo pixel no hay zoom continuo: se salta de un escalón al otro.
		zoom_a_nivel(_nivel_mas_cercano() + (1 if factor > 1.0 else -1))
		return
	var antes := get_global_mouse_position()
	var z := clampf(zoom.x * factor, ZOOM_MIN, ZOOM_MAX)
	zoom = Vector2(z, z)
	# Mantiene bajo el cursor el punto del mundo que había antes de hacer zoom.
	position += antes - get_global_mouse_position()

func _process(delta: float) -> void:
	# Si sueltas la cámara arrastrando y luego mueves al personaje, vuelve a
	# engancharse sola. Sin esto te quedas mirando el mar sin saber por qué.
	if modo == Modo.LIBRE and is_instance_valid(objetivo) and not _arrastrando:
		if Controles.eje_movimiento() != Vector2.ZERO:
			modo = Modo.SEGUIR

	if modo == Modo.SEGUIR and is_instance_valid(objetivo):
		position = position.lerp(objetivo.position, clampf(SUAVIZADO * delta, 0.0, 1.0))
	# En modo libre la vista se mueve arrastrando con el botón derecho. El
	# teclado no la toca: las flechas se quedan sin asignar hasta que haya un
	# modo de cámara libre de verdad.

	# El cuadrado a píxel va al final, después de mover: el movimiento lógico
	# sigue siendo continuo y libre; lo único que se redondea es dónde se
	# dibuja la vista.
	if modo_pixel:
		_cuadrar_a_pixel()

# ---------------------------------------------------------------------------
# LÍMITES
# ---------------------------------------------------------------------------

## Encierra la cámara en el rombo que ocupa una rejilla de casillas, con un
## margen para que no quede el mapa pegado al borde de la pantalla.
func limitar_a_casillas(rejilla: Rect2i, margen: float = 320.0) -> void:
	var esquinas := [
		Iso.centro(rejilla.position.x, rejilla.position.y),
		Iso.centro(rejilla.end.x, rejilla.position.y),
		Iso.centro(rejilla.end.x, rejilla.end.y),
		Iso.centro(rejilla.position.x, rejilla.end.y),
	]
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for p: Vector2 in esquinas:
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	limit_left = int(min_x - margen)
	limit_right = int(max_x + margen)
	limit_top = int(min_y - margen)
	limit_bottom = int(max_y + margen)

func sin_limites() -> void:
	limit_left = -10000000
	limit_right = 10000000
	limit_top = -10000000
	limit_bottom = 10000000
