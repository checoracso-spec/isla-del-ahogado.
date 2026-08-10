class_name EstacionCrafteo
extends Interactuable
## Punto de fabricación manual. La estación sólo identifica su tipo; la
## ejecución, recetas, inventario y guardado viven en CraftingManager.

@export var estacion_id: String = ""
@export var accion: String = "Fabricar"
var horario_id: String = ""
var actividades_productivas: Array = ["trabajar"]
var actividades_preparacion: Array = []

func set_estacion_id(id: String) -> void:
	estacion_id = id

func set_accion(texto: String) -> void:
	accion = texto

func set_horario_id(id: String) -> void:
	horario_id = id

func set_actividades_productivas(actividades: Array) -> void:
	actividades_productivas = actividades

func set_actividades_preparacion(actividades: Array) -> void:
	actividades_preparacion = actividades

func estado_operativo() -> String:
	if horario_id == "":
		return "abierta"
	var horario: HorarioData = BaseDeDatos.horario(horario_id)
	return horario.estado_en(Reloj.hora, actividades_productivas, actividades_preparacion) if horario != null else "detenida"

func _ready() -> void:
	alcance = 1.8
	super()

func texto_accion() -> String:
	match estado_operativo():
		"preparando": return "Preparativos - " + estacion_id
		"detenida": return "Cerrado - Vuelve al amanecer"
		_: return accion

func disponible(_quien: Node) -> bool:
	return estacion_id != "" and not CraftingManager.recetas_para(estacion_id).is_empty()

func interactuar(quien: Node) -> void:
	CraftingManager.abrir(estacion_id, quien, horario_id, actividades_productivas,
		actividades_preparacion)
