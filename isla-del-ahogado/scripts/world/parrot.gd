extends Node2D

## Compañero cómico: muestra comentarios breves provocados por acciones del mundo.

var current_line := "¡Qué isla tan poco higiénica!"
var line_timer := 0.0

func comment(event_name: String) -> void:
	var lines := {
		"loot": ["¡Pío! Revisa los bolsillos, capitán.", "Ese cadáver tenía mejor inventario que tú."],
		"bury": ["Un hoyo y listo. Qué profesionalismo.", "Espero que no ronque bajo tierra."],
		"craft": ["¡Artesanía! O chatarra con autoestima."],
		"sleep": ["Dormir es la mejor estrategia naval."],
		"donate": ["El dios acepta doblones. Qué sorpresa."],
		"combat": ["¡Al abordaje! Y que nadie mire mis alas."]
	}
	var choices: Array = lines.get(event_name, ["Pío. Eso ha sido cuestionable."])
	current_line = str(choices[randi() % choices.size()])
	line_timer = 4.0
	queue_redraw()

func _process(delta: float) -> void:
	if line_timer > 0.0:
		line_timer -= delta
		if line_timer <= 0.0:
			current_line = ""
			queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(0.0, 8.0), 15.0, Color(0.02, 0.03, 0.04, 0.4))
	draw_circle(Vector2(0.0, -4.0), 12.0, Color("#6da9a1"))
	draw_circle(Vector2(-4.0, -5.0), 2.0, Color("#ffe4a3"))
	draw_circle(Vector2(4.0, -5.0), 2.0, Color("#ffe4a3"))
	draw_colored_polygon(PackedVector2Array([Vector2(9.0, -2.0), Vector2(18.0, 2.0), Vector2(9.0, 6.0)]), Color("#d99148"))
	if not current_line.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(-150.0, -32.0), current_line, HORIZONTAL_ALIGNMENT_LEFT, 300.0, 14, Color("#fff0c8"))
