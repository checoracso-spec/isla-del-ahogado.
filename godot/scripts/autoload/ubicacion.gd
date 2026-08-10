extends Node
## AUTOLOAD: Ubicacion
##
## DÓNDE está el jugador. Nada más.
##
## Deliberadamente separado de `Bolsa`, que lleva QUÉ tiene. Son dos preguntas
## distintas y se guardan en secciones distintas:
##
##   Bolsa     -> sección "jugador":  mochila, oro, salud, energía, herramientas
##   Ubicacion -> sección "mundo":    zona actual, casilla y dirección
##
## Cuando existan varias zonas (interiores, cubiertas de barco, otras islas),
## este nodo es el que sabrá a cuál devolverte al cargar la partida.
##
## Nota sobre el formato: los Vector2 se guardan como pares de números, no como
## Vector2. JSON no sabe de Vector2 y los convertiría en el texto "(3, 5)", que
## al volver a leerlo ya no es un vector.

signal zona_cambiada(zona: String)

const ZONA_EXTERIOR := "isla"

var zona: String = ZONA_EXTERIOR
var pos: Vector2 = Vector2.ZERO
var direccion: Vector2 = Vector2(1, 1)

## Sólo tienen valor mientras se está dentro de un interior. Con estos cuatro
## datos se puede reconstruir la situación exacta al cargar: en qué interior,
## de qué edificio, por qué puerta se entró y a qué casilla de fuera se sale.
var interior_id: String = ""
var edificio_instancia: String = ""
var puerta_instancia: String = ""
var retorno: Vector2 = Vector2.ZERO      ## casilla del exterior junto a la puerta

## false hasta que alguien la haya fijado o cargado. Evita colocar al jugador
## en (0,0) —que es mar abierto— en una partida nueva.
var hay_dato: bool = false

func _ready() -> void:
	Guardado.registrar("mundo", _serializar, _cargar)

## La llama el jugador mientras camina.
func anotar(p_pos: Vector2, p_direccion: Vector2) -> void:
	pos = p_pos
	direccion = p_direccion
	hay_dato = true

func cambiar_zona(nueva: String, p_pos: Vector2) -> void:
	zona = nueva
	pos = p_pos
	hay_dato = true
	zona_cambiada.emit(nueva)

## Apunta todo lo necesario para poder volver a entrar tras cargar.
func entrar_en(p_interior_id: String, p_edificio: String, p_puerta: String,
		p_retorno: Vector2, p_pos: Vector2) -> void:
	interior_id = p_interior_id
	edificio_instancia = p_edificio
	puerta_instancia = p_puerta
	retorno = p_retorno
	cambiar_zona(p_interior_id, p_pos)

func volver_al_exterior(p_pos: Vector2) -> void:
	interior_id = ""
	edificio_instancia = ""
	puerta_instancia = ""
	cambiar_zona(ZONA_EXTERIOR, p_pos)

func en_exterior() -> bool:
	return zona == ZONA_EXTERIOR

func _serializar() -> Dictionary:
	return {
		"zona": zona,
		"pos": [pos.x, pos.y],
		"direccion": [direccion.x, direccion.y],
		"retorno": [retorno.x, retorno.y],
		"interior_id": interior_id,
		"edificio_instancia": edificio_instancia,
		"puerta_instancia": puerta_instancia,
	}

func _cargar(d: Dictionary) -> void:
	zona = str(d.get("zona", ZONA_EXTERIOR))
	pos = _a_vector(d.get("pos", []), Vector2.ZERO)
	direccion = _a_vector(d.get("direccion", []), Vector2(1, 1))
	retorno = _a_vector(d.get("retorno", []), Vector2.ZERO)
	interior_id = str(d.get("interior_id", ""))
	edificio_instancia = str(d.get("edificio_instancia", ""))
	puerta_instancia = str(d.get("puerta_instancia", ""))
	hay_dato = true
	zona_cambiada.emit(zona)

func _a_vector(crudo: Variant, por_defecto: Vector2) -> Vector2:
	if typeof(crudo) != TYPE_ARRAY:
		return por_defecto
	var a: Array = crudo
	if a.size() < 2:
		return por_defecto
	return Vector2(float(a[0]), float(a[1]))
