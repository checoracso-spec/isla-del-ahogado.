class_name AnimalData
extends Resource

## Fauna de la isla. tipo: ganado | utilidad | plaga

@export var id: String = ""
@export var nombre: String = ""
@export var tipo: String = "ganado"
@export var produce: Dictionary = {}         ## id_item -> cantidad por día
@export var consume: Dictionary = {}         ## id_item -> cantidad por día
@export var contramedida: String = ""        ## qué lo neutraliza (para las plagas)
@export var descripcion: String = ""

static func desde_dic(d: Dictionary) -> AnimalData:
	var a := AnimalData.new()
	a.id = d.get("id", "")
	a.nombre = d.get("nombre", a.id)
	a.tipo = d.get("tipo", "ganado")
	a.produce = d.get("produce", {}).duplicate(true)
	a.consume = d.get("consume", {}).duplicate(true)
	a.contramedida = d.get("contramedida", "")
	a.descripcion = d.get("desc", "")
	a.resource_name = a.nombre
	return a
