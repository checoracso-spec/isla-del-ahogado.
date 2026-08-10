class_name RecetaData
extends Resource

## Una transformación: entran insumos, salen productos, tarda unos segundos.
##
## "sustitutos" es la clave del plan de contingencia. Formato:
##   { "aceite_imperial": { "id": "grasa_ballena", "ratio": 2.0, "calidad": 0.7 } }
## Léase: si falta Aceite Imperial, gasta 2 Grasa de Ballena por cada 1 que falte,
## y el lote sale al 70% de calidad. La producción NO se detiene.

@export var id: String = ""
@export var nombre: String = ""
@export var estacion: String = ""            ## id del edificio que la ejecuta
@export var insumos: Dictionary = {}         ## id_item -> cantidad
@export var productos: Dictionary = {}       ## id_item -> cantidad
@export var sustitutos: Dictionary = {}      ## id_item_original -> {id, ratio, calidad}
@export var segundos: float = 6.0            ## duración de un lote a 1 trabajador
@export var energia: float = 5.0              ## coste al fabricar manualmente

static func desde_dic(d: Dictionary) -> RecetaData:
	var r := RecetaData.new()
	r.id = d.get("id", "")
	r.nombre = d.get("nombre", r.id)
	r.estacion = d.get("estacion", "")
	r.insumos = d.get("insumos", {}).duplicate(true)
	r.productos = d.get("productos", {}).duplicate(true)
	r.sustitutos = d.get("sustitutos", {}).duplicate(true)
	r.segundos = float(d.get("segundos", 6.0))
	r.energia = float(d.get("energia", 5.0))
	r.resource_name = r.nombre
	return r
