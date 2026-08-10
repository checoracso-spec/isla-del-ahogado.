class_name AnimalData
extends Resource

## Fauna de la isla. tipo: ganado | utilidad | plaga

@export var id: String = ""
@export var nombre: String = ""
@export var tipo: String = "ganado"
@export var habitat: String = "isla"
@export var domestico: bool = false
@export var velocidad: float = 2.0
@export var radio_deambular: float = 4.0
@export var produce: Dictionary = {}         ## id_item -> cantidad por día
@export var consume: Dictionary = {}         ## id_item -> cantidad por día
@export var contramedida: String = ""        ## qué lo neutraliza (para las plagas)
@export var descripcion: String = ""

static func desde_dic(d: Dictionary) -> AnimalData:
	var a := AnimalData.new()
	a.id = d.get("id", "")
	a.nombre = d.get("nombre", a.id)
	a.tipo = d.get("tipo", "ganado")
	a.habitat = str(d.get("habitat", "isla"))
	a.domestico = bool(d.get("domestico", false))
	a.velocidad = maxf(0.1, float(d.get("velocidad", 2.0)))
	a.radio_deambular = maxf(0.5, float(d.get("radio_deambular", 4.0)))
	a.produce = d.get("produce", {}).duplicate(true)
	a.consume = d.get("consume", {}).duplicate(true)
	a.contramedida = d.get("contramedida", "")
	a.descripcion = d.get("desc", "")
	a.resource_name = a.nombre
	return a
