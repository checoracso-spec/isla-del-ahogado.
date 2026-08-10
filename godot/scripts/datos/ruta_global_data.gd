class_name RutaGlobalData
extends Resource
const ScriptRuta := preload("res://scripts/datos/ruta_global_data.gd")
## Conexión navegable entre dos destinos del mapa global.

@export var id: String = ""
@export var origen: String = ""
@export var destino: String = ""
@export var barco_requerido: String = "balandra"
@export var dias: int = 1
@export var riesgo: float = 0.0
@export var descripcion: String = ""

static func desde_dic(d: Dictionary) -> Resource:
	var ruta = ScriptRuta.new()
	ruta.id = str(d.get("id", ""))
	ruta.origen = str(d.get("origen", ""))
	ruta.destino = str(d.get("destino", ""))
	ruta.barco_requerido = str(d.get("barco", "balandra"))
	ruta.dias = maxi(1, int(d.get("dias", 1)))
	ruta.riesgo = clampf(float(d.get("riesgo", 0.0)), 0.0, 1.0)
	ruta.descripcion = str(d.get("descripcion", ""))
	ruta.resource_name = ruta.id
	return ruta
