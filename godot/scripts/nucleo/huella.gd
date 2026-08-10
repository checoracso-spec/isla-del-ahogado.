class_name Huella
extends RefCounted
## El sitio que ocupa un actor en el suelo, en casillas.
##
## Sustituye al `radio` de antes, que tenía dos defectos que se iban a notar en
## cuanto hubiera algo más grande que una persona:
##
##   1. Sólo servía para cuadrados. Un carro es 2×1 y un caballo 1×2.
##   2. Sólo se comprobaban las cuatro esquinas. Una vaca de lado 1.2 podía
##      atravesar una pared fina que le quedara justo en el centro, sin que
##      ninguna esquina la tocara.
##
## Ahora se recorren TODAS las casillas que la caja pisa, así que el tamaño
## deja de importar. Sigue siendo un rectángulo alineado con los ejes de la
## rejilla; la rotación por dirección se añadirá cuando haya carros.

const MARGEN := 0.0001      ## evita agarrar la casilla vecina al tocar el borde justo

var ancho: float = 0.52     ## en casillas, de lado a lado (no es un radio)
var alto: float = 0.52

func _init(p_ancho: float = 0.52, p_alto: float = 0.52) -> void:
	ancho = maxf(0.01, p_ancho)
	alto = maxf(0.01, p_alto)

static func cuadrada(lado: float) -> Huella:
	return Huella.new(lado, lado)

## Para cuando alguien piense en radios: lado = 2 × radio.
static func desde_radio(radio: float) -> Huella:
	return Huella.new(radio * 2.0, radio * 2.0)

func area_en(centro: Vector2) -> Rect2:
	return Rect2(centro.x - ancho * 0.5, centro.y - alto * 0.5, ancho, alto)

## Todas las casillas enteras que toca la caja centrada en `centro`.
func casillas_bajo(centro: Vector2) -> Array[Vector2i]:
	var res: Array[Vector2i] = []
	var x0 := int(floor(centro.x - ancho * 0.5))
	var x1 := int(floor(centro.x + ancho * 0.5 - MARGEN))
	var y0 := int(floor(centro.y - alto * 0.5))
	var y1 := int(floor(centro.y + alto * 0.5 - MARGEN))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			res.append(Vector2i(x, y))
	return res

func _to_string() -> String:
	return "Huella(%.2f × %.2f)" % [ancho, alto]
