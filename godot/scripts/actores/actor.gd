class_name Actor
extends Node2D
## Todo lo que anda por el mundo: jugador, tripulación, NPCs y animales.
##
## Concentra lo que se programaría tres veces: posición en casillas, dirección,
## estado, movimiento con colisión y nivel de detalle. Quien hereda sólo decide
## HACIA DÓNDE quiere ir; el "puedo o no puedo" lo resuelve esta clase
## preguntando a su Transitable.
##
## Nota sobre coordenadas: la posición interna va en CASILLAS con decimales,
## no en píxeles. La conversión a pantalla la hace Iso y sólo Iso. Así el mismo
## actor funciona igual en la isla, dentro de una casa o en un barco.

## Cuánto trabajo merece este actor según lo lejos que esté del jugador.
## Todavía nadie lo cambia, pero la firma ya está para cuando haya 100 NPCs.
enum Detalle { CERCA, LEJOS, DORMIDO }

const CARDINALES := ["abajo", "izquierda", "arriba", "derecha"]

@export var velocidad: float = 3.2          ## casillas por segundo

## El sitio que ocupa en el suelo. Rectangular y por actor: una persona ocupa
## poco más de media casilla, un caballo ocupará 1×2 y un carro 2×1, sin que
## haya que tocar ni el movimiento ni la transitabilidad.
var huella: Huella = Huella.cuadrada(0.56)

var pos_tile: Vector2 = Vector2.ZERO        ## posición continua, en casillas
var direccion: Vector2 = Vector2(1, 1)      ## hacia dónde mira, en casillas
var estado: String = "idle"                 ## idle | andar | comer | dormir | trabajar
var detalle: int = Detalle.CERCA
var transitable: Transitable = null

var _fase: float = 0.0                      ## para el vaivén al andar
var _acumulado: float = 0.0                 ## para actualizar a ritmo lento

# ---------------------------------------------------------------------------
# COLOCACIÓN
# ---------------------------------------------------------------------------

## Coloca sin comprobar nada. Para aparecer al empezar o al cargar partida.
func colocar(casilla: Vector2) -> void:
	pos_tile = casilla
	_aplicar_posicion()

## Coloca buscando hueco si la casilla estuviera ocupada.
func colocar_seguro(casilla: Vector2) -> void:
	if transitable != null:
		var t := transitable.casilla_libre_cerca(
			Vector2i(int(floor(casilla.x)), int(floor(casilla.y))))
		colocar(Vector2(t) + Vector2(0.5, 0.5))
	else:
		colocar(casilla)

func casilla() -> Vector2i:
	return Vector2i(int(floor(pos_tile.x)), int(floor(pos_tile.y)))

func _aplicar_posicion() -> void:
	# Los pies del actor caen en el vértice inferior de su casilla: es lo que
	# hace que el orden por Y lo tape o lo destape correctamente.
	position = Iso.centro_fino(pos_tile) + Vector2(0, Iso.MEDIO_Y)

# ---------------------------------------------------------------------------
# MOVIMIENTO
# ---------------------------------------------------------------------------

## Intenta desplazarse en la dirección dada (en casillas, sin normalizar).
## Prueba los dos ejes por separado: si te chocas con una pared en diagonal,
## resbalas a lo largo de ella en vez de quedarte clavado.
## Devuelve true si se movió algo.
func mover(dir: Vector2, delta: float, factor: float = 1.0) -> bool:
	if dir == Vector2.ZERO:
		estado = "idle"
		return false

	var paso := dir.normalized() * velocidad * factor * delta
	var antes := pos_tile
	var nueva := pos_tile

	var probar_x := Vector2(nueva.x + paso.x, nueva.y)
	if _libre(probar_x):
		nueva = probar_x
	var probar_y := Vector2(nueva.x, nueva.y + paso.y)
	if _libre(probar_y):
		nueva = probar_y

	var movido := nueva.distance_squared_to(antes) > 0.0000001
	if movido:
		pos_tile = nueva
		direccion = dir.normalized()
		_fase += delta * 7.0
		estado = "andar"
		_aplicar_posicion()
	else:
		estado = "idle"
	return movido

## Camina hacia un punto. Devuelve true cuando ya está encima.
func ir_hacia(destino: Vector2, delta: float, margen: float = 0.08) -> bool:
	var d := destino - pos_tile
	if d.length() <= margen:
		estado = "idle"
		return true
	mover(d, delta, minf(1.0, d.length() / maxf(0.001, velocidad * delta)))
	return false

func _libre(candidata: Vector2) -> bool:
	if transitable == null:
		return true
	return transitable.cabe_en(candidata, huella)

# ---------------------------------------------------------------------------
# DIRECCIÓN Y ANIMACIÓN
# ---------------------------------------------------------------------------

## En isométrico "derecha" no es la X de las casillas, es la X de la pantalla.
func direccion_pantalla() -> Vector2:
	return Vector2(direccion.x - direccion.y, (direccion.x + direccion.y) * 0.5)

func mirando_derecha() -> bool:
	return direccion_pantalla().x >= 0.0

## abajo | izquierda | arriba | derecha — la clave de animación que usarán
## los sprites cuando lleguen (walk_down, walk_left, ...).
func cardinal() -> String:
	var p := direccion_pantalla()
	if absf(p.x) >= absf(p.y):
		return "derecha" if p.x >= 0.0 else "izquierda"
	return "abajo" if p.y >= 0.0 else "arriba"

## La clave completa de animación. Hoy nadie la consume; cuando haya sprites,
## esto es lo único que hay que enchufar al AnimatedSprite2D.
func clave_animacion() -> String:
	if estado == "andar":
		return "walk_" + cardinal()
	return estado

# ---------------------------------------------------------------------------
# CICLO
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if Reloj.pausado:
		return
	match detalle:
		Detalle.DORMIDO:
			return
		Detalle.LEJOS:
			# Un actor lejano piensa cuatro veces por segundo, no sesenta.
			_acumulado += delta
			if _acumulado < 0.25:
				return
			actualizar(_acumulado, detalle)
			_acumulado = 0.0
		_:
			actualizar(delta, detalle)
	queue_redraw()

## Sobrescribir. Aquí decide cada tipo de actor qué quiere hacer.
func actualizar(_delta: float, _nivel: int) -> void:
	pass

func _draw() -> void:
	Figura.dibujar(self, _opciones_figura())

## Sobrescribir para cambiar el aspecto sin tocar el dibujo.
func _opciones_figura() -> Dictionary:
	return {
		"andando": estado == "andar",
		"fase": _fase,
		"mirando_derecha": mirando_derecha(),
	}
