class_name PanelDiarioMisiones
extends PanelContainer
## Vista de solo lectura del estado de las misiones del jugador.

var _lista: VBoxContainer
var _resumen: Label

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(520, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.08, 0.11, 0.97)
	estilo.set_corner_radius_all(8)
	estilo.border_color = GlobalColors.PALETA["cian_magico"]
	estilo.set_border_width_all(1)
	add_theme_stylebox_override("panel", estilo)

	var margen := MarginContainer.new()
	margen.name = "Margen"
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	add_child(margen)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	margen.add_child(caja)

	var titulo := Label.new()
	titulo.text = "Diario de Misiones"
	titulo.add_theme_font_size_override("font_size", 20)
	titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	caja.add_child(titulo)

	var desplazamiento := ScrollContainer.new()
	desplazamiento.custom_minimum_size = Vector2(0, 360)
	desplazamiento.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caja.add_child(desplazamiento)
	_lista = VBoxContainer.new()
	_lista.name = "ListaMisiones"
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 8)
	desplazamiento.add_child(_lista)

	_resumen = Label.new()
	_resumen.name = "ResumenMisiones"
	_resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_resumen.add_theme_color_override("font_color", Color("d9dde6"))
	_lista.add_child(_resumen)

	var cerrar := Button.new()
	cerrar.text = "Cerrar  [J / Esc]"
	cerrar.pressed.connect(cerrar_panel)
	caja.add_child(cerrar)

	Bolsa.objetos_cambiados.connect(_repintar)
	Misiones.estado_cambiado.connect(_al_cambiar_estado)

func abrir() -> void:
	visible = true
	_repintar()

func cerrar_panel() -> void:
	visible = false

func alternar() -> void:
	if visible:
		cerrar_panel()
	else:
		abrir()

func abierto() -> bool:
	return visible

func _al_cambiar_estado(_mision_id: String, _estado: int) -> void:
	_repintar()

func _repintar() -> void:
	if not visible or _resumen == null:
		return
	var ids := Misiones.ids()
	if ids.is_empty():
		_resumen.text = "Sin misiones registradas."
		return

	var lineas: Array[String] = []
	for id in ids:
		var definicion: MisionData = BaseDeDatos.mision(id)
		if definicion == null:
			continue
		var personaje: PersonajeData = BaseDeDatos.personaje(definicion.npc_id)
		var nombre_npc := personaje.nombre if personaje != null else "Desconocido"
		var objetivo := Misiones.objetivo_item(id)
		var texto_objetivo := "Objetivo no disponible."
		if objetivo.get("tipo", "") == "item":
			var item_id := str(objetivo.get("item_id", ""))
			var requerido := int(objetivo.get("cantidad", 0))
			var actual := mini(Bolsa.mochila.cantidad(item_id), requerido)
			texto_objetivo = "%s: %d/%d" % [BaseDeDatos.nombre_item(item_id), actual, requerido]
		lineas.append("%s\nSolicitante: %s\nEstado: %s\nObjetivo: %s" % [
			definicion.nombre, nombre_npc, _nombre_estado(Misiones.estado(id)), texto_objetivo])
	_resumen.text = "\n\n".join(lineas) if not lineas.is_empty() else "Sin misiones registradas."

func _nombre_estado(estado: int) -> String:
	match estado:
		Misiones.QuestState.AVAILABLE:
			return "Disponible"
		Misiones.QuestState.ACCEPTED:
			return "Aceptada"
		Misiones.QuestState.OBJECTIVE_COMPLETE:
			return "Objetivo completado"
		Misiones.QuestState.TURNED_IN:
			return "Entregada"
		_:
			return "Desconocido"

func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("diario_misiones") or (
		evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE):
		cerrar_panel()
		get_viewport().set_input_as_handled()
