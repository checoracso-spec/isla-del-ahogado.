class_name DestinoData
extends Resource
const ScriptDestino := preload("res://scripts/datos/destino_data.gd")
## Una isla, ciudad, fortaleza o zona mayor del mapa global.

@export var id: String = ""
@export var nombre: String = ""
@export var tipo: String = "isla"       ## isla | ciudad | fortaleza | colonia
@export var mapa_id: String = ""
@export var coordenadas: Vector2 = Vector2.ZERO
@export var puerto: bool = false
@export var descripcion: String = ""

static func desde_dic(d: Dictionary) -> Resource:
	var destino = ScriptDestino.new()
	destino.id = str(d.get("id", ""))
	destino.nombre = str(d.get("nombre", destino.id))
	destino.tipo = str(d.get("tipo", "isla"))
	destino.mapa_id = str(d.get("mapa_id", destino.id))
	var c: Variant = d.get("coordenadas", Vector2.ZERO)
	destino.coordenadas = c if c is Vector2 else Vector2.ZERO
	destino.puerto = bool(d.get("puerto", false))
	destino.descripcion = str(d.get("descripcion", ""))
	destino.resource_name = destino.nombre
	return destino
