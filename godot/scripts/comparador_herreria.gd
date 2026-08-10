extends Node2D
## Herramienta visual: compara el interior jugable con la referencia externa.
## No se carga desde mundo.tscn y no participa en el guardado.

const InteriorEscenaScript := preload("res://scripts/interiores/interior_escena.gd")
const DioramaPreviewScript := preload("res://scripts/visual/diorama_preview.gd")

func _ready() -> void:
	RenderingServer.set_default_clear_color(GlobalColors.PALETA["azul_noche"])
	var def: InteriorDefinicion = BaseDeDatos.interior("interior_herreria_pb")
	if def == null:
		push_error("No existe interior_herreria_pb")
		return

	var jugable := InteriorEscenaScript.new()
	jugable.name = "InteriorJugable"
	jugable.position = Vector2(300, 390)
	add_child(jugable)
	jugable.construir(def, Vector2i.ZERO, "herreria", "comparador_herreria")

	var referencia := DioramaPreviewScript.new()
	referencia.name = "ReferenciaPack"
	referencia.position = Vector2(960, 390)
	referencia.clave_catalogo = "herreria_ref"
	referencia.escala_visual = 1.45
	add_child(referencia)

	_add_label("INTERIOR JUGABLE", Vector2(70, 40), 26, GlobalColors.get_color_interaccion())
	_add_label("REFERENCIA DEL PACK EXTERNO", Vector2(700, 40), 26, GlobalColors.get_color_interaccion())
	_add_label("Izquierda: suelo, muros, muebles y transitabilidad del juego.  Derecha: arte de referencia; no sustituye colisiones.",
		Vector2(70, 700), 16, GlobalColors.PALETA["plata_salitre"])

func _add_label(texto: String, posicion: Vector2, tamano: int, color: Color) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.position = posicion
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	add_child(etiqueta)
