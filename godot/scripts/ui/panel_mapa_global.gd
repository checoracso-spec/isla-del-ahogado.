class_name PanelMapaGlobal
extends PanelContainer

var _selector: OptionButton
var _info: Label
var _estado: Label
var _rutas: Array = []
var _ruta_id: String = ""

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(430, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.08, 0.11, 0.98)
	estilo.set_corner_radius_all(8)
	estilo.border_color = GlobalColors.get_color_interaccion()
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
	titulo.text = "Mapa global · Rutas navegables"
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	caja.add_child(titulo)
	_estado = Label.new()
	caja.add_child(_estado)
	_selector = OptionButton.new()
	_selector.name = "SelectorDestino"
	_selector.item_selected.connect(func(indice: int):
		_ruta_id = str(_selector.get_item_metadata(indice))
		_actualizar_info())
	caja.add_child(_selector)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_theme_color_override("font_color", GlobalColors.PALETA["plata_salitre"])
	caja.add_child(_info)
	var zarpar := Button.new()
	zarpar.text = "Iniciar viaje"
	zarpar.name = "IniciarViajeGlobal"
	zarpar.pressed.connect(_iniciar)
	caja.add_child(zarpar)
	var cerrar := Button.new()
	cerrar.text = "Cerrar  [Esc]"
	cerrar.pressed.connect(cerrar_panel)
	caja.add_child(cerrar)
	MapaGlobal.viaje_iniciado.connect(func(_ruta: Resource, _llegada: float):
		_actualizar_info())
	MapaGlobal.viaje_completado.connect(func(_destino: String): cerrar_panel())

func abrir() -> void:
	visible = true
	_selector.clear()
	_rutas = MapaGlobal.rutas_desde()
	_ruta_id = ""
	for ruta: Resource in _rutas:
		var destino: Resource = BaseDeDatos.destino(str(ruta.destino))
		var nombre: String = str(destino.nombre) if destino != null else str(ruta.destino)
		_selector.add_item("%s · %d días" % [nombre, ruta.dias])
		_selector.set_item_metadata(_selector.item_count - 1, ruta.id)
	if not _rutas.is_empty():
		_selector.select(0)
		_ruta_id = str(_selector.get_item_metadata(0))
	_estado.text = "Origen: %s" % _nombre_destino(MapaGlobal.ubicacion_actual)
	_actualizar_info()

func cerrar_panel() -> void:
	visible = false

func abierto() -> bool:
	return visible

func _iniciar() -> void:
	if _ruta_id != "" and MapaGlobal.iniciar_viaje(_ruta_id):
		_estado.text = "Viaje en curso"
		_actualizar_info()

func _actualizar_info() -> void:
	if _info == null:
		return
	var ruta: Resource = MapaGlobal.ruta(_ruta_id)
	if ruta == null:
		_info.text = "No hay rutas disponibles desde esta ubicación."
		return
	var barco_texto := ""
	if MapaGlobal.viajando():
		barco_texto = "Barco en navegación: %s" % str(MapaGlobal.viaje_activo.get("barco_id", ""))
	else:
		var barco_id := FlotaMundo.disponible_para(str(ruta.barco_requerido), str(ruta.origen))
		barco_texto = "Barco asignable: %s" % barco_id if barco_id != "" else "Sin barco disponible en este puerto"
	_info.text = "%s\nBarco requerido: %s\n%s\nRiesgo estimado: %d%%\n%s" % [
		ruta.descripcion, ruta.barco_requerido, barco_texto,
		int(ruta.riesgo * 100.0), "Viaje en curso." if MapaGlobal.viajando() else "Listo para zarpar."]

func _nombre_destino(id: String) -> String:
	var destino: Resource = BaseDeDatos.destino(id)
	return destino.nombre if destino != null else id

func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		cerrar_panel()
		get_viewport().set_input_as_handled()
