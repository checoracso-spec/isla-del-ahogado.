class_name BarcoData
extends Resource
## Definición estática de una clase de barco.
##
## No contiene posición ni carga viva: esos datos pertenecen a la instancia
## guardable de `FlotaMundo`.

@export var id: String = ""
@export var nombre: String = ""
@export var tipo: String = "balandra"
@export var capacidad_volumen: float = 20.0
@export var capacidad_peso: float = 100.0
@export var velocidad: float = 1.0
@export var salud_max: int = 100
@export var armadura: int = 0
@export var canones_max: int = 0
@export var tripulacion_min: int = 1

static func desde_dic(d: Dictionary) -> Resource:
	var b = load("res://scripts/datos/barco_data.gd").new()
	b.id = str(d.get("id", ""))
	b.nombre = str(d.get("nombre", b.id))
	b.tipo = str(d.get("tipo", b.id))
	b.capacidad_volumen = maxf(1.0, float(d.get("capacidad_volumen", 20.0)))
	b.capacidad_peso = maxf(1.0, float(d.get("capacidad_peso", 100.0)))
	b.velocidad = maxf(0.1, float(d.get("velocidad", 1.0)))
	b.salud_max = maxi(1, int(d.get("salud_max", 100)))
	b.armadura = maxi(0, int(d.get("armadura", 0)))
	b.canones_max = maxi(0, int(d.get("canones_max", 0)))
	b.tripulacion_min = maxi(1, int(d.get("tripulacion_min", 1)))
	b.resource_name = b.nombre
	return b
