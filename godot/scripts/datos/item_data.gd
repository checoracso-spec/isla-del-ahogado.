class_name ItemData
extends Resource

## Un material, comida, moneda o bien comercial.
## No se escriben a mano: BaseDeDatos los fabrica desde una tabla de diccionarios.

## Tipos válidos: crudo, procesado, comida, moneda, comercial, contenedor,
## mision, prestigio, intangible (la moral no ocupa sitio en los cofres).
@export var id: String = ""
@export var nombre: String = ""
@export var tipo: String = "crudo"
@export var peso: float = 1.0        ## lastre por unidad — limita lo que cabe en un barco
@export var volumen: float = 1.0     ## espacio en bodega por unidad
@export var valor_base: int = 1      ## doblones antes de la fluctuación del mercado negro
@export var moral: float = 0.0       ## alivio de motín al consumirse (el ron)
@export var comida: float = 0.0      ## saciedad al consumirse (las raciones)
@export var descripcion: String = ""

static func desde_dic(d: Dictionary) -> ItemData:
	var it := ItemData.new()
	it.id = d.get("id", "")
	it.nombre = d.get("nombre", it.id)
	it.tipo = d.get("tipo", "crudo")
	it.peso = float(d.get("peso", 1.0))
	it.volumen = float(d.get("volumen", 1.0))
	it.valor_base = int(d.get("valor", 1))
	it.moral = float(d.get("moral", 0.0))
	it.comida = float(d.get("comida", 0.0))
	it.descripcion = d.get("desc", "")
	it.resource_name = it.nombre
	return it

func es_intangible() -> bool:
	return tipo == "intangible"
