class_name MisionData
extends Resource

## Definición mínima de una misión: quién la ofrece, sus textos, un objetivo
## de objeto y una recompensa.
## Las instancias de estado y su persistencia siguen perteneciendo a Misiones.

@export var id: String = ""
@export var nombre: String = ""
@export var npc_id: String = ""
@export var objetivo_item_id: String = ""
@export var objetivo_cantidad: int = 1
@export var recompensa_doblones: int = 0
@export var dialogo_aceptacion: String = ""
@export var dialogo_progreso: String = ""
@export var dialogo_entrega: String = ""
@export var dialogo_completada: String = ""
@export var requisito_mision_id: String = ""

static func desde_dic(d: Dictionary) -> MisionData:
	var mision := MisionData.new()
	mision.id = str(d.get("id", ""))
	mision.nombre = str(d.get("nombre", mision.id))
	mision.npc_id = str(d.get("npc_id", ""))
	mision.objetivo_item_id = str(d.get("objetivo_item_id", ""))
	mision.objetivo_cantidad = maxi(1, int(d.get("objetivo_cantidad", 1)))
	mision.recompensa_doblones = maxi(0, int(d.get("recompensa_doblones", 0)))
	mision.dialogo_aceptacion = str(d.get("dialogo_aceptacion", ""))
	mision.dialogo_progreso = str(d.get("dialogo_progreso", ""))
	mision.dialogo_entrega = str(d.get("dialogo_entrega", ""))
	mision.dialogo_completada = str(d.get("dialogo_completada", ""))
	mision.requisito_mision_id = str(d.get("requisito_mision_id", ""))
	mision.resource_name = mision.nombre
	return mision
