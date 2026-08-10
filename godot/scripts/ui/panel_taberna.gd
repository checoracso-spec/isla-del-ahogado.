class_name PanelTaberna
extends PanelContainer

var _estado: Label
var _lista: VBoxContainer
var _aviso := ""

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(430, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.08, 0.11, 0.97)
	estilo.set_corner_radius_all(8)
	estilo.border_color = GlobalColors.PALETA["madera_clara"]
	estilo.set_border_width_all(1)
	add_theme_stylebox_override("panel", estilo)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	add_child(margen)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	margen.add_child(caja)
	var titulo := Label.new()
	titulo.text = "Taberna de la Sirena Salada"
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	caja.add_child(titulo)
	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_estado)
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 6)
	caja.add_child(_lista)
	var cerrar := Button.new()
	cerrar.text = "Cerrar  [Esc]"
	cerrar.pressed.connect(cerrar_panel)
	caja.add_child(cerrar)
	TabernaManager.resultado.connect(func(mensaje: String):
		if visible:
			_aviso = mensaje
			_repintar())
	TabernaManager.actualizado.connect(func():
		if visible:
			_repintar())
	Bolsa.oro_cambiado.connect(func(_valor):
		if visible:
			_repintar())

func abrir() -> void:
	_aviso = ""
	visible = true
	_repintar()

func cerrar_panel() -> void:
	visible = false
	_aviso = ""
	TabernaManager.cerrar()

func abierto() -> bool:
	return visible

func _repintar() -> void:
	if not visible or _lista == null:
		return
	var estado := "Activa" if TabernaManager.estado_actual == "activa" else ("Preparativos" if TabernaManager.estado_actual == "preparando" else "Cerrada")
	_estado.text = _aviso if _aviso != "" else "%s  ·  Raciones: %d  ·  Ron: %d  ·  Energía: %.0f/%.0f  ·  Tripulación: %d" % [
		estado,
		Bolsa.mochila.cantidad("raciones"), Bolsa.mochila.cantidad("ron"), Bolsa.energia, Bolsa.energia_max, Motin.tripulacion]
	for hijo in _lista.get_children():
		hijo.queue_free()
	var ronda := Button.new()
	ronda.text = "Servir una ronda"
	ronda.disabled = Bolsa.mochila.cantidad("raciones") < 1 or Bolsa.mochila.cantidad("ron") < 1
	ronda.pressed.connect(TabernaManager.servir_ronda)
	_lista.add_child(ronda)
	var contratar := Button.new()
	contratar.text = "Contratar marinero (%d doblones)" % TabernaManager.COSTE_MARINERO
	contratar.disabled = TabernaManager.estado_actual != "activa" or Bolsa.oro < TabernaManager.COSTE_MARINERO
	contratar.pressed.connect(TabernaManager.contratar_marinero)
	_lista.add_child(contratar)
	var rumor := Button.new()
	rumor.text = "Escuchar un rumor"
	rumor.pressed.connect(TabernaManager.escuchar_rumor)
	_lista.add_child(rumor)

func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		cerrar_panel()
		get_viewport().set_input_as_handled()
