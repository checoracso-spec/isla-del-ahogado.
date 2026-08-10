class_name TransitableRejilla
extends Transitable
## Transitabilidad de un espacio cerrado y pequeño: una habitación, una bodega,
## una cubierta. Rectángulo con casillas bloqueadas sueltas.
##
## Frente a `TransitableIsla`, que consulta el terreno generado, aquí todo se
## declara: es lo que permite que un interior salga de un archivo de datos.

var ancho: int = 1
var alto: int = 1
var bloqueadas: Dictionary = {}          ## Vector2i -> motivo

func _init(p_ancho: int = 1, p_alto: int = 1) -> void:
	ancho = maxi(1, p_ancho)
	alto = maxi(1, p_alto)

func puede_pisar(casilla: Vector2i) -> bool:
	if casilla.x < 0 or casilla.y < 0 or casilla.x >= ancho or casilla.y >= alto:
		return false
	return not bloqueadas.has(casilla)

func limites() -> Rect2i:
	return Rect2i(0, 0, ancho, alto)

func bloquear(casilla: Vector2i, motivo: String = "muro") -> void:
	bloqueadas[casilla] = motivo

func liberar(casilla: Vector2i) -> void:
	bloqueadas.erase(casilla)

## El perímetro entero como muro, que es lo que quiere casi cualquier interior.
func amurallar() -> void:
	for x in ancho:
		bloquear(Vector2i(x, 0))
		bloquear(Vector2i(x, alto - 1))
	for y in alto:
		bloquear(Vector2i(0, y))
		bloquear(Vector2i(ancho - 1, y))
