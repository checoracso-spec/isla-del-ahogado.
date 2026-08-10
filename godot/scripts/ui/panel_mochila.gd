class_name PanelMochila
extends PanelContainer
## Vista de la mochila del jugador. No modifica cantidades ni conoce Almacen.

var _lista: VBoxContainer
var _titulo: Label
var _estado: Label
var _aviso := ""

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(470, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.08, 0.11, 0.97)
	estilo.set_corner_radius_all(8)
	estilo.border_color = GlobalColors.PALETA["cian_magico"]
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
	_titulo.text = "Mochila del corsario"
	_titulo.add_theme_font_size_override("font_size", 18)
	_titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	caja.add_child(_titulo)
	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.add_theme_color_override("font_color", Color("d9dde6"))
	caja.add_child(_estado)

	var desplazamiento := ScrollContainer.new()
	desplazamiento.custom_minimum_size = Vector2(0, 350)
	desplazamiento.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caja.add_child(desplazamiento)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 4)
	desplazamiento.add_child(_lista)

	var cerrar := Button.new()
	cerrar.text = "Cerrar  [I / Esc]"
	cerrar.pressed.connect(cerrar_panel)
	caja.add_child(cerrar)

	Bolsa.objetos_cambiados.connect(_repintar)
	Bolsa.oro_cambiado.connect(func(_valor): _repintar())
	Bolsa.salud_cambiada.connect(func(_valor): _repintar())
	Bolsa.energia_cambiada.connect(func(_valor): _repintar())

func abrir() -> void:
	_aviso = ""
	visible = true
	_repintar()

func cerrar_panel() -> void:
	visible = false
	_aviso = ""

func alternar() -> void:
	if visible:
		cerrar_panel()
	else:
		abrir()

func abierto() -> bool:
	return visible

func _repintar() -> void:
	if not visible or _lista == null:
		return
	var resumen := "Oro: %d  ·  Salud: %.0f/%.0f  ·  Energía: %.0f/%.0f\nCarga: %.1f / %.1f" % [
		Bolsa.oro, Bolsa.salud, Bolsa.salud_max, Bolsa.energia, Bolsa.energia_max,
		Bolsa.mochila.volumen(), Bolsa.mochila.capacidad]
	var equipo := ", ".join(Bolsa.herramientas) if not Bolsa.herramientas.is_empty() else "ninguna"
	_estado.text = _aviso if _aviso != "" else resumen + "\nEquipadas: " + equipo
	for hijo in _lista.get_children():
		hijo.queue_free()
	var filas := Bolsa.mochila.lista()
	if filas.is_empty():
		var vacio := Label.new()
		vacio.text = "La mochila está vacía."
		vacio.add_theme_color_override("font_color", Color("8b94a6"))
		_lista.add_child(vacio)
		return
	for fila_datos in filas:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		var nombre := Label.new()
		nombre.text = str(fila_datos["nombre"])
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nombre.add_theme_color_override("font_color", Color("d9dde6"))
		fila.add_child(nombre)
		var cantidad := Label.new()
		cantidad.text = "× %d" % int(fila_datos["cantidad"])
		cantidad.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cantidad.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
		fila.add_child(cantidad)
		var uno := Button.new()
		uno.text = "Guardar 1"
		uno.pressed.connect(_depositar.bind(str(fila_datos["id"]), 1))
		fila.add_child(uno)
		var todo := Button.new()
		todo.text = "Guardar todo"
		todo.pressed.connect(_depositar.bind(str(fila_datos["id"]), int(fila_datos["cantidad"])))
		fila.add_child(todo)
		var item: ItemData = BaseDeDatos.item(str(fila_datos["id"]))
		if item != null and (item.moral > 0.0 or item.comida > 0.0):
			var usar := Button.new()
			usar.text = "Consumir"
			usar.pressed.connect(_consumir.bind(str(fila_datos["id"])))
			fila.add_child(usar)
		elif item != null and item.tipo == "herramienta":
			var equipar := Button.new()
			equipar.text = "Equipar" if str(fila_datos["id"]) not in Bolsa.herramientas else "Equipada"
			equipar.disabled = str(fila_datos["id"]) in Bolsa.herramientas
			equipar.pressed.connect(_equipar.bind(str(fila_datos["id"])))
			fila.add_child(equipar)
		_lista.add_child(fila)

func _depositar(id: String, cantidad: int) -> void:
	var movido := Bolsa.depositar_en_almacen(id, cantidad)
	_aviso = "%d unidad(es) guardada(s) en el almacén." % movido if movido > 0 else "No se pudo guardar ese objeto."
	_repintar()

func _consumir(id: String) -> void:
	var resultado := Bolsa.consumir(id)
	_aviso = str(resultado.get("motivo", ""))
	_repintar()

func _equipar(id: String) -> void:
	var resultado := Bolsa.equipar_desde_mochila(id)
	_aviso = str(resultado.get("motivo", ""))
	_repintar()

func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("inventario") or (evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE):
		cerrar_panel()
		get_viewport().set_input_as_handled()
