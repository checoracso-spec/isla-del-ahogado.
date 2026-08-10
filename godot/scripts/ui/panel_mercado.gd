class_name PanelMercado
extends PanelContainer
## Compra y venta básica, separada de la logística del asentamiento.

var _lista: VBoxContainer
var _estado: Label
var _aviso := ""

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(520, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.08, 0.11, 0.97)
	estilo.set_corner_radius_all(8)
	estilo.border_color = GlobalColors.PALETA["oro_llama"]
	estilo.set_border_width_all(1)
	add_theme_stylebox_override("panel", estilo)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	add_child(margen)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	margen.add_child(caja)
	var titulo := Label.new()
	titulo.text = "Mercado de Portobello"
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	caja.add_child(titulo)
	_estado = Label.new()
	caja.add_child(_estado)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 390)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caja.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 5)
	scroll.add_child(_lista)
	var cerrar := Button.new()
	cerrar.text = "Cerrar  [Esc]"
	cerrar.pressed.connect(cerrar_panel)
	caja.add_child(cerrar)
	MercadoManager.actualizado.connect(_repintar)
	MercadoManager.operacion_realizada.connect(func(mensaje: String):
		if visible:
			_aviso = mensaje
			_repintar())

func abrir() -> void:
	_aviso = ""
	visible = true
	_repintar()

func cerrar_panel() -> void:
	visible = false
	_aviso = ""
	MercadoManager.cerrar()

func abierto() -> bool:
	return visible

func _repintar() -> void:
	if not visible or _lista == null:
		return
	_estado.text = _aviso if _aviso != "" else "Doblones: %d" % Bolsa.oro
	for hijo in _lista.get_children():
		hijo.queue_free()
	var comprar := Label.new()
	comprar.text = "Comprar"
	comprar.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	_lista.add_child(comprar)
	for fila in MercadoManager.lista_stock():
		var linea := HBoxContainer.new()
		var nombre := Label.new()
		nombre.text = "%s × %d" % [fila["nombre"], fila["cantidad"]]
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linea.add_child(nombre)
		var precio := Label.new()
		precio.text = "%d doblones" % MercadoManager.precio_compra(str(fila["id"]))
		linea.add_child(precio)
		var boton := Button.new()
		boton.text = "Comprar 1"
		boton.pressed.connect(func(): MercadoManager.comprar(str(fila["id"]), 1))
		linea.add_child(boton)
		_lista.add_child(linea)
	var separador := HSeparator.new()
	_lista.add_child(separador)
	var vender := Label.new()
	vender.text = "Vender desde la mochila"
	vender.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	_lista.add_child(vender)
	for fila in Bolsa.mochila.lista():
		var linea := HBoxContainer.new()
		var nombre := Label.new()
		nombre.text = "%s × %d" % [fila["nombre"], fila["cantidad"]]
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linea.add_child(nombre)
		var precio := Label.new()
		precio.text = "%d doblones" % MercadoManager.precio_venta(str(fila["id"]))
		linea.add_child(precio)
		var boton := Button.new()
		boton.text = "Vender 1"
		boton.pressed.connect(func(): MercadoManager.vender(str(fila["id"]), 1))
		linea.add_child(boton)
		_lista.add_child(linea)

func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		cerrar_panel()
		get_viewport().set_input_as_handled()
