class_name PuestoMuelle
extends Interactuable

signal gestionar(estado: String)

var horario_id := "muelle"
var actividades_productivas: Array = ["trabajar"]

func _ready() -> void:
	alcance = 1.8
	super()
	queue_redraw()

func estado_operativo() -> String:
	var horario: HorarioData = BaseDeDatos.horario(horario_id)
	return horario.estado_en(Reloj.hora, actividades_productivas) if horario != null else "detenida"

func texto_accion() -> String:
	return "Gestionar Carga" if estado_operativo() == "abierta" else "Detenido por la noche"

func interactuar(_quien: Node) -> void:
	gestionar.emit(estado_operativo())

func _draw() -> void:
	var madera := GlobalColors.PALETA["madera_base"]
	var clara := GlobalColors.PALETA["arena_madera"]
	var azul := GlobalColors.PALETA["azul_base"]
	draw_colored_polygon(PackedVector2Array([
		Vector2(-38, 0), Vector2(0, 19), Vector2(38, 0), Vector2(0, -19)]), madera.darkened(0.25))
	draw_rect(Rect2(-30, -35, 60, 22), clara)
	draw_line(Vector2(-24, -13), Vector2(-24, 14), madera.darkened(0.4), 4.0)
	draw_line(Vector2(24, -13), Vector2(24, 14), madera.darkened(0.4), 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -31), Vector2(0, -23), Vector2(18, -31), Vector2(0, -39)]), azul)
