class_name PuestoTaberna
extends Interactuable
## Mostrador provisional de la taberna.

var horario_id := ""
var actividades_productivas: Array = ["trabajar"]
var actividades_preparacion: Array = []

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
	queue_redraw()

func texto_accion() -> String:
	match estado_operativo():
		"preparando": return "Hablar (Preparativos)"
		"detenida": return "Cerrada - Vuelve al amanecer"
		_: return "Entrar - Taberna Activa"

func interactuar(_quien: Node) -> void:
	TabernaManager.abrir(estado_operativo())

func _draw() -> void:
	var madera := GlobalColors.PALETA["madera_base"]
	var clara := GlobalColors.PALETA["arena_madera"]
	var oro := GlobalColors.PALETA["oro_llama"]
	draw_colored_polygon(PackedVector2Array([
		Vector2(-52, 0), Vector2(0, 26), Vector2(52, 0), Vector2(0, -26)]), madera.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-44, -36), Vector2(44, -36), Vector2(44, -12), Vector2(-44, -12)]), clara)
	draw_circle(Vector2(-23, -26), 6, oro)
	draw_circle(Vector2(23, -26), 6, oro)
