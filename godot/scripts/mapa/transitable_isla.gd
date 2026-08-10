class_name TransitableIsla
extends Transitable
## Transitabilidad del exterior: manda el terreno y mandan los edificios.
##
## El terreno ya sabía decir si una casilla es pisable (`GeneradorIsla`), pero
## nadie se lo preguntaba. La ocupación de los edificios, en cambio, se
## calculaba al colocarlos y se tiraba. Aquí se juntan las dos cosas y se
## conservan, que es lo que hace falta para que el jugador no atraviese casas.

var isla: GeneradorIsla
var ocupadas: Dictionary = {}            ## Vector2i -> id del edificio
var excepciones: Dictionary = {}         ## Vector2i -> true (puertas, umbrales)

func _init(p_isla: GeneradorIsla) -> void:
	isla = p_isla

func puede_pisar(casilla: Vector2i) -> bool:
	if isla == null:
		return false
	if excepciones.has(casilla):
		return true
	if ocupadas.has(casilla):
		return false
	return isla.es_transitable(casilla.x, casilla.y)

func limites() -> Rect2i:
	if isla == null:
		return Rect2i()
	return Rect2i(0, 0, isla.ancho, isla.alto)

## Marca la huella de un edificio como sólida.
func ocupar(origen: Vector2i, lado: int, quien: String) -> void:
	for dy in lado:
		for dx in lado:
			ocupadas[Vector2i(origen.x + dx, origen.y + dy)] = quien

func liberar(origen: Vector2i, lado: int) -> void:
	for dy in lado:
		for dx in lado:
			ocupadas.erase(Vector2i(origen.x + dx, origen.y + dy))

## Un umbral que sí se puede pisar aunque caiga dentro de un edificio.
func abrir_paso(casilla: Vector2i) -> void:
	excepciones[casilla] = true

func quien_ocupa(casilla: Vector2i) -> String:
	return str(ocupadas.get(casilla, ""))
