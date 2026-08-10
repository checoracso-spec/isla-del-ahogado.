class_name InteriorDefinicion
extends Resource
## Un interior descrito con datos, no con código.
##
## El objetivo es que añadir la taberna, la herrería o el camarote del capitán
## sea escribir un diccionario más en la tabla, sin tocar ni una línea de
## lógica. Por eso aquí no hay nada de dibujo ni de comportamiento: sólo
## medidas, dónde está la puerta y qué muebles hay.

@export var id: String = ""
@export var nombre: String = ""
@export var tipo: String = "casa"           ## casa | taberna | herreria | almacen | bodega
@export var ancho: int = 8
@export var alto: int = 8
## Casilla interior pegada a la puerta: donde aparece quien entra.
@export var entrada: Vector2i = Vector2i(1, 1)
## Muebles: [{ "tipo": "mesa", "casilla": Vector2i, "solido": true }]
@export var muebles: Array = []
@export var suelo: String = "madera"        ## madera | piedra | tierra
## Claves opcionales del manifiesto. Si faltan, InteriorEscena conserva el
## dibujo provisional por código y el interior sigue siendo jugable.
@export var asset_suelo: String = ""
@export var asset_muro_norte: String = ""
@export var asset_muro_oeste: String = ""
## Sólo la planta conectada con la calle monta la puerta de salida exterior.
## Las demás plantas regresan mediante TransicionZona.
@export var salida_exterior: bool = true

static func desde_dic(d: Dictionary) -> InteriorDefinicion:
	var i := InteriorDefinicion.new()
	i.id = str(d.get("id", ""))
	i.nombre = str(d.get("nombre", i.id))
	i.tipo = str(d.get("tipo", "casa"))
	i.ancho = int(d.get("ancho", 8))
	i.alto = int(d.get("alto", 8))
	i.suelo = str(d.get("suelo", "madera"))
	i.asset_suelo = str(d.get("asset_suelo", ""))
	i.asset_muro_norte = str(d.get("asset_muro_norte", ""))
	i.asset_muro_oeste = str(d.get("asset_muro_oeste", ""))
	i.salida_exterior = bool(d.get("salida_exterior", true))
	var e: Variant = d.get("entrada", Vector2i(1, 1))
	i.entrada = e if e is Vector2i else Vector2i(1, 1)
	i.muebles = (d.get("muebles", []) as Array).duplicate(true)
	i.resource_name = i.nombre
	return i

## La casilla de dentro donde aparece quien entra, garantizando que cae dentro
## de las paredes aunque los datos vengan mal.
func entrada_valida() -> Vector2i:
	return Vector2i(clampi(entrada.x, 1, ancho - 2), clampi(entrada.y, 1, alto - 2))
