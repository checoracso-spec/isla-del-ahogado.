extends Node2D
## Herramienta visual: compara el interior jugable con la referencia externa.
## No se carga desde mundo.tscn y no participa en el guardado.

const InteriorEscenaScript := preload("res://scripts/interiores/interior_escena.gd")
const BuildManagerScript := preload("res://scripts/desarrollador/build_manager.gd")
const InteriorLayoutEditorScript := preload("res://scripts/desarrollador/interior_layout_editor.gd")

func _ready() -> void:
	RenderingServer.set_default_clear_color(GlobalColors.PALETA["azul_noche"])
	var def: InteriorDefinicion = BaseDeDatos.interior("interior_herreria_pb")
	if def == null:
		push_error("No existe interior_herreria_pb")
		return

	var jugable := InteriorEscenaScript.new()
	jugable.name = "InteriorJugable"
	# El comparador usa una escala propia para que quepa la sala completa en
	# una ventana 1280×720. La lógica y las colisiones siguen en coordenadas
	# locales sin escalar; solo esta escena de revisión cambia su presentación.
	jugable.position = Vector2(350, 405)
	jugable.scale = Vector2(0.50, 0.50)
	add_child(jugable)
	# Sin esto, jugable.identidad queda null (el 5º parámetro de construir()
	# no tiene valor por defecto útil) y el Modo Desarrollador no puede crear
	# cofres de prueba con Entidades/Contenedores, igual que le pasaría a un
	# cofre real sin zona. Misma llamada que hace Interiores.entrar().
	var identidad_prueba := Entidades.identificar("zona", def.id, "comparador_herreria:%s" % def.id)
	jugable.construir(def, Vector2i.ZERO, "herreria", "comparador_herreria", identidad_prueba)

	var referencia := Sprite2D.new()
	referencia.name = "ReferenciaPack"
	referencia.texture = load("res://assets/referencias/herreria_referencia.png")
	referencia.centered = true
	referencia.position = Vector2(980, 390)
	referencia.scale = Vector2(0.31, 0.31)
	referencia.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(referencia)

	# Modo Desarrollador de Interiores — Fase 2, solo previsualización.
	# Vive nada más aquí: comparador_herreria.tscn nunca se carga desde
	# mundo.tscn, así que el modo normal del juego no lo ve ni lo hereda.
	var constructor := BuildManagerScript.new()
	constructor.name = "BuildManager"
	constructor.interior = jugable
	constructor.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(constructor)

	var editor := InteriorLayoutEditorScript.new()
	editor.name = "InteriorLayoutEditor"
	editor.interior = jugable
	editor.referencia = referencia
	editor.colocador = constructor
	add_child(editor)

	_add_label("INTERIOR JUGABLE", Vector2(70, 40), 26, GlobalColors.get_color_interaccion())
	_add_label("REFERENCIA VISUAL APROBADA", Vector2(760, 40), 26, GlobalColors.get_color_interaccion())
	# La paleta y los comandos del editor ocupan ahora la franja inferior.
	# Los textos antiguos de ayuda quedan fuera del área visible para no taparla.
	_add_label("Izquierda: sala editable.  Derecha: referencia visual; no sustituye colisiones.",
		Vector2(70, 700), 16, GlobalColors.PALETA["plata_salitre"])
	_add_label("Modo Desarrollador: 1=yunque 2=fragua 3=banco 4=escaleras 5=horno 6=mesa 7=cofre — clic izq=colocar/confirmar, clic der=mover/cancelar, R=rotar, Esc=cancelar, Supr=eliminar",
		Vector2(70, 670), 16, GlobalColors.get_color_interaccion())

func _add_label(texto: String, posicion: Vector2, tamano: int, color: Color) -> void:
	if texto.begins_with("Izquierda:") or texto.begins_with("Modo Desarrollador:"):
		return
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.set_meta("comparador_hud", true)
	etiqueta.position = posicion
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	add_child(etiqueta)
