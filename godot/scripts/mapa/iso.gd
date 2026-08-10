class_name Iso
extends RefCounted
## Las cuentas del isométrico, en un solo sitio.
##
## Un tile es un rombo de 128 × 64. El tile (x, y) tiene su CENTRO en
##   ( (x - y) · 64 ,  (x + y) · 32 )
## que es exactamente lo que hace Godot con TILE_SHAPE_ISOMETRIC + DIAMOND_DOWN,
## así que el mapa de tiles y los objetos sueltos usan el mismo sistema.
##
## Las ESQUINAS del rombo son la clave de las transiciones playa/agua:
##   vértice superior  -> esquina (x,   y)
##   vértice derecho   -> esquina (x+1, y)
##   vértice inferior  -> esquina (x+1, y+1)
##   vértice izquierdo -> esquina (x,   y+1)
## Por eso el terreno se guarda por esquinas, no por casillas.

const ANCHO := 128
const ALTO := 64
const MEDIO_X := 64.0
const MEDIO_Y := 32.0

## Godot coloca el centro del tile (0,0) en (64, 32), no en el origen. Si el
## mapa de tiles y los objetos no comparten este desplazamiento, los edificios
## salen medio tile corridos respecto al suelo.
const ORIGEN := Vector2(MEDIO_X, MEDIO_Y)

static func centro(x: int, y: int) -> Vector2:
	return Vector2((x - y) * MEDIO_X, (x + y) * MEDIO_Y) + ORIGEN

static func centro_v(t: Vector2i) -> Vector2:
	return centro(t.x, t.y)

## Punto inferior del rombo: donde un edificio o un personaje "apoya" en el suelo.
static func apoyo(x: int, y: int) -> Vector2:
	return centro(x, y) + Vector2(0.0, MEDIO_Y)

## Igual pero con coordenadas continuas, para personajes que caminan entre tiles.
static func centro_fino(pos: Vector2) -> Vector2:
	return Vector2((pos.x - pos.y) * MEDIO_X, (pos.x + pos.y) * MEDIO_Y) + ORIGEN

## De píxeles a casilla. Sirve para saber sobre qué tile está el ratón.
static func a_tile(p: Vector2) -> Vector2i:
	var q := p - ORIGEN
	var fx := q.x / MEDIO_X
	var fy := q.y / MEDIO_Y
	return Vector2i(int(floor((fy + fx) * 0.5)), int(floor((fy - fx) * 0.5)))

## Las cuatro esquinas de un tile, en el orden de los bits de máscara:
## 0 = arriba, 1 = derecha, 2 = abajo, 3 = izquierda.
static func esquinas(x: int, y: int) -> Array[Vector2i]:
	return [
		Vector2i(x, y),
		Vector2i(x + 1, y),
		Vector2i(x + 1, y + 1),
		Vector2i(x, y + 1),
	]

## Punto inferior de un edificio que ocupa un cuadrado de `lado` casillas
## empezando en (x, y). Es el punto que hay que hacer coincidir con la base
## del sprite para que el edificio no flote ni se hunda.
static func apoyo_bloque(x: int, y: int, lado: int) -> Vector2:
	return apoyo(x + lado - 1, y + lado - 1)
