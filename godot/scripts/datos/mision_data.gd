class_name MisionData
extends Resource

## Definición mínima de una misión: un objetivo de objeto y una recompensa.
## Las instancias de estado y su persistencia siguen perteneciendo a Misiones.

@export var id: String = ""
@export var nombre: String = ""
@export var objetivo_item_id: String = ""
@export var objetivo_cantidad: int = 1
@export var recompensa_doblones: int = 0

static func desde_dic(d: Dictionary) -> MisionData:
	var mision := MisionData.new()
	mision.id = str(d.get("id", ""))
	mision.nombre = str(d.get("nombre", mision.id))
	mision.objetivo_item_id = str(d.get("objetivo_item_id", ""))
	mision.objetivo_cantidad = maxi(1, int(d.get("objetivo_cantidad", 1)))
	mision.recompensa_doblones = maxi(0, int(d.get("recompensa_doblones", 0)))
	mision.resource_name = mision.nombre
	return mision
