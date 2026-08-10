class_name PuestoMercado
extends Interactuable
## Mostrador provisional dibujado por código hasta tener arte del mercado.

func _ready() -> void:
	alcance = 1.8
	super()
	queue_redraw()

func texto_accion() -> String:
	return "Abrir mercado"

func interactuar(_quien: Node) -> void:
	MercadoManager.abrir()

func _draw() -> void:
	var madera := GlobalColors.PALETA["madera_base"]
	var clara := GlobalColors.PALETA["arena_madera"]
	var metal := GlobalColors.PALETA["acero_gris"]
	var suelo := Vector2(0, 0)
	draw_colored_polygon(PackedVector2Array([
		suelo + Vector2(-48, 0), suelo + Vector2(0, 24), suelo + Vector2(48, 0), suelo + Vector2(0, -24)]), madera.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-42, -42), Vector2(42, -42), Vector2(42, -18), Vector2(-42, -18)]), clara)
	draw_line(Vector2(-42, -18), Vector2(42, -18), metal, 2.0)
	draw_line(Vector2(-36, -18), Vector2(-36, 10), madera.darkened(0.4), 4.0)
	draw_line(Vector2(36, -18), Vector2(36, 10), madera.darkened(0.4), 4.0)
