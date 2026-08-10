class_name PanelCofre
extends PanelContainer
## Interfaz mínima para vaciar un cofre. Provisional y a propósito: sirve para
## demostrar el trasvase cofre → mochila sin inventar todavía la pantalla de
## inventario del juego.
##
## No toca cantidades a mano: usa `Inventario.transferir_a`, que es la única
## forma de que nada se duplique ni se pierda por el camino.

signal cerrado()

var _cofre: Cofre
var _lista: VBoxContainer
var _titulo: Label

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(500, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.08, 0.11, 0.96)
	estilo.set_corner_radius_all(8)
	estilo.border_color = Color(0.42, 0.35, 0.22)
	estilo.set_border_width_all(1)
	add_theme_stylebox_override("panel", estilo)

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	margen.add_child(caja)

	_titulo = Label.new()
	_titulo.text = "Cofre"
	_titulo.add_theme_font_size_override("font_size", 17)
	_titulo.add_theme_color_override("font_color", Color("e8c76a"))
	caja.add_child(_titulo)

	var desplazamiento := ScrollContainer.new()
	desplazamiento.custom_minimum_size = Vector2(0, 390)
	desplazamiento.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caja.add_child(desplazamiento)
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 4)
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desplazamiento.add_child(_lista)

	var cerrar := Button.new()
	cerrar.text = "Cerrar  [Esc]"
	cerrar.pressed.connect(cerrar_panel)
	caja.add_child(cerrar)

func abrir(cofre: Cofre) -> void:
	_cofre = cofre
	visible = true
	_repintar()

func cerrar_panel() -> void:
	visible = false
	_cofre = null
	cerrado.emit()

func abierto() -> bool:
	return visible

func _repintar() -> void:
	for hijo in _lista.get_children():
		hijo.queue_free()
	if _cofre == null:
		return
	var inv := _cofre.inventario()
	if inv == null or inv.esta_vacio():
		var vacio := Label.new()
		vacio.text = "Está vacío."
		vacio.add_theme_color_override("font_color", Color("8b94a6"))
		_lista.add_child(vacio)
		_montar_desde_mochila()
		return

	for fila in inv.lista():
		var linea := HBoxContainer.new()
		linea.add_theme_constant_override("separation", 8)
		var etiqueta := Label.new()
		etiqueta.text = "%s × %d" % [fila["nombre"], fila["cantidad"]]
		etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		etiqueta.add_theme_color_override("font_color", Color("d9dde6"))
		linea.add_child(etiqueta)
		var boton := Button.new()
		boton.text = "Tomar 1"
		boton.pressed.connect(_tomar.bind(str(fila["id"]), 1))
		linea.add_child(boton)
		var todo := Button.new()
		todo.text = "Tomar todo"
		todo.pressed.connect(_tomar.bind(str(fila["id"]), int(fila["cantidad"])))
		linea.add_child(todo)
		_lista.add_child(linea)
	_montar_desde_mochila()

func _tomar(id: String, cantidad: int) -> void:
	if _cofre == null:
		return
	var inv := _cofre.inventario()
	if inv == null:
		return
	inv.transferir_a(Bolsa.mochila, id, cantidad)
	_cofre.queue_redraw()
	_repintar()

func _montar_desde_mochila() -> void:
	var separador := HSeparator.new()
	_lista.add_child(separador)
	var titulo := Label.new()
	titulo.text = "Desde la mochila"
	titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	_lista.add_child(titulo)
	var filas := Bolsa.mochila.lista()
	if filas.is_empty():
		var vacio := Label.new()
		vacio.text = "La mochila estÃ¡ vacÃ­a."
		vacio.add_theme_color_override("font_color", Color("8b94a6"))
		_lista.add_child(vacio)
		return
	for fila in filas:
		var linea := HBoxContainer.new()
		linea.add_theme_constant_override("separation", 6)
		var etiqueta := Label.new()
		etiqueta.text = "%s Ã— %d" % [fila["nombre"], fila["cantidad"]]
		etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linea.add_child(etiqueta)
		var uno := Button.new()
		uno.text = "Guardar 1"
		uno.pressed.connect(_guardar.bind(str(fila["id"]), 1))
		linea.add_child(uno)
		var todo := Button.new()
		todo.text = "Guardar todo"
		todo.pressed.connect(_guardar.bind(str(fila["id"]), int(fila["cantidad"])))
		linea.add_child(todo)
		_lista.add_child(linea)

func _guardar(id: String, cantidad: int) -> void:
	if _cofre == null:
		return
	var inv := _cofre.inventario()
	if inv == null:
		return
	Bolsa.mochila.transferir_a(inv, id, cantidad)
	_cofre.queue_redraw()
	_repintar()

func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		cerrar_panel()
		get_viewport().set_input_as_handled()
