class_name PanelCrafteo
extends PanelContainer
## Panel provisional para fabricar manualmente en una estación.

var _estacion_id := ""
var _lista: VBoxContainer
var _titulo: Label
var _estado: Label
var _aviso := ""

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(390, 0)
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

	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 18)
	_titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	caja.add_child(_titulo)
	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.add_theme_color_override("font_color", Color("d9dde6"))
	caja.add_child(_estado)
	var desplazamiento := ScrollContainer.new()
	desplazamiento.custom_minimum_size = Vector2(0, 360)
	desplazamiento.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caja.add_child(desplazamiento)
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 5)
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desplazamiento.add_child(_lista)
	var cerrar := Button.new()
	cerrar.text = "Cerrar  [Esc]"
	cerrar.pressed.connect(cerrar_panel)
	caja.add_child(cerrar)

	CraftingManager.actualizada.connect(_repintar)
	CraftingManager.fabricacion_completada.connect(func(_id, _productos, _calidad): _repintar())
	CraftingManager.fallo.connect(func(mensaje: String):
		if visible:
			_aviso = mensaje
			_repintar.call_deferred())

func abrir(estacion_id: String) -> void:
	_estacion_id = estacion_id
	_aviso = ""
	visible = true
	_repintar()

func cerrar_panel() -> void:
	visible = false
	_estacion_id = ""
	_aviso = ""
	CraftingManager.cerrar()

func abierto() -> bool:
	return visible

func _repintar() -> void:
	if not visible or _lista == null:
		return
	for hijo in _lista.get_children():
		hijo.queue_free()
	if CraftingManager.trabajando():
		var receta_activa := CraftingManager.receta_actual(str(CraftingManager.trabajo.get("receta_id", "")))
		_estado.text = "Trabajando: %s — %d%%" % [receta_activa.nombre if receta_activa else "receta", int(CraftingManager.porcentaje() * 100.0)]
	else:
		_estado.text = _aviso if _aviso != "" else "Energía: %.0f / %.0f" % [Bolsa.energia, Bolsa.energia_max]
	_titulo.text = "Herrería · Fabricación" if _estacion_id == "herreria" else "Fabricación"
	for receta in CraftingManager.recetas_para(_estacion_id):
		var fila := VBoxContainer.new()
		var nombre := Label.new()
		nombre.text = receta.nombre
		nombre.add_theme_color_override("font_color", Color("f0e3c2"))
		fila.add_child(nombre)
		var detalle := Label.new()
		detalle.text = "Entrada: %s\nSalida: %s\nEnergía: %.0f · %.1fs" % [
			_texto_items(receta.insumos), _texto_items(receta.productos), receta.energia, receta.segundos]
		detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detalle.add_theme_font_size_override("font_size", 12)
		fila.add_child(detalle)
		var boton := Button.new()
		var puede := CraftingManager.puede_fabricar(receta.id)
		boton.text = "Fabricar" if puede.get("ok", false) else "Fabricar (faltan materiales)"
		boton.disabled = not puede.get("ok", false)
		boton.pressed.connect(func(): CraftingManager.fabricar(receta.id))
		fila.add_child(boton)
		if not puede.get("ok", false) and not CraftingManager.trabajando():
			var traer := Button.new()
			traer.text = "Traer insumos desde el almacén"
			traer.pressed.connect(func():
				var resultado := CraftingManager.abastecer(receta.id)
				_aviso = str(resultado.get("motivo", ""))
				_repintar())
			fila.add_child(traer)
		_lista.add_child(fila)

func _texto_items(items: Dictionary) -> String:
	var partes: Array[String] = []
	for id in items:
		partes.append("%d× %s" % [int(items[id]), BaseDeDatos.nombre_item(str(id))])
	return ", ".join(partes) if not partes.is_empty() else "ninguno"

func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		cerrar_panel()
		get_viewport().set_input_as_handled()
