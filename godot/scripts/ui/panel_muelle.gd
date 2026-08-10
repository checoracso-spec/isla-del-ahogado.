class_name PanelMuelle
extends PanelContainer

signal mapa_global_solicitado()

var _estado: Label
var _lista: RichTextLabel
var _descargar_boton: Button
var _zarpar_boton: Button
var _ruta_selector: OptionButton
var _ruta_info: Label
var _interceptado_info: Label
var _soltar_boton: Button
var _luchar_boton: Button
var _grua_boton: Button
var _mapa_boton: Button
var _ruta_id := "portobello"
var _interceptado_id := ""
var _aviso := ""
var _estacion_abierta := false

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(430, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.08, 0.11, 0.97)
	estilo.set_corner_radius_all(8)
	estilo.border_color = GlobalColors.PALETA["azul_base"]
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
	titulo.text = "Muelle de Grúa · Gestión de Carga"
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	caja.add_child(titulo)
	_estado = Label.new()
	caja.add_child(_estado)
	_interceptado_info = Label.new()
	_interceptado_info.name = "AvisoInterceptacion"
	_interceptado_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_interceptado_info.add_theme_color_override("font_color", GlobalColors.PALETA["naranja_fuego"])
	_interceptado_info.visible = false
	caja.add_child(_interceptado_info)
	_soltar_boton = Button.new()
	_soltar_boton.name = "SoltarLastre"
	_soltar_boton.text = "Soltar lastre"
	_soltar_boton.pressed.connect(func(): _decidir_interceptacion("soltar"))
	_soltar_boton.visible = false
	caja.add_child(_soltar_boton)
	_luchar_boton = Button.new()
	_luchar_boton.name = "LucharInterceptacion"
	_luchar_boton.text = "Luchar"
	_luchar_boton.pressed.connect(func(): _decidir_interceptacion("luchar"))
	_luchar_boton.visible = false
	caja.add_child(_luchar_boton)
	_lista = RichTextLabel.new()
	_lista.bbcode_enabled = true
	_lista.custom_minimum_size = Vector2(0, 180)
	_lista.fit_content = true
	caja.add_child(_lista)
	_grua_boton = Button.new()
	_grua_boton.name = "ActivarGrua"
	_grua_boton.pressed.connect(_activar_grua)
	caja.add_child(_grua_boton)
	_mapa_boton = Button.new()
	_mapa_boton.name = "AbrirMapaGlobal"
	_mapa_boton.text = "Abrir mapa global"
	_mapa_boton.pressed.connect(func(): mapa_global_solicitado.emit())
	caja.add_child(_mapa_boton)
	_descargar_boton = Button.new()
	_descargar_boton.name = "DescargarPuerto"
	_descargar_boton.text = "Descargar cargamentos atracados"
	_descargar_boton.pressed.connect(_descargar)
	caja.add_child(_descargar_boton)
	_ruta_selector = OptionButton.new()
	_ruta_selector.name = "SelectorRuta"
	for id in RastreoCarga.rutas_disponibles():
		var r: Dictionary = RastreoCarga.ruta(id)
		_ruta_selector.add_item(str(r.get("nombre", id)))
		_ruta_selector.set_item_metadata(_ruta_selector.item_count - 1, id)
		_ruta_selector.item_selected.connect(func(indice: int):
			_ruta_id = str(_ruta_selector.get_item_metadata(indice))
			_actualizar_ruta_info()
	)
	var ids := RastreoCarga.rutas_disponibles()
	for i in ids.size():
		if ids[i] == _ruta_id:
			_ruta_selector.select(i)
			break
	caja.add_child(_ruta_selector)
	_ruta_info = Label.new()
	_ruta_info.name = "InfoRuta"
	_ruta_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ruta_info.add_theme_font_size_override("font_size", 13)
	_ruta_info.add_theme_color_override("font_color", GlobalColors.PALETA["plata_salitre"])
	caja.add_child(_ruta_info)
	_zarpar_boton = Button.new()
	_zarpar_boton.name = "EnviarExpedicion"
	_zarpar_boton.text = "Enviar expedicion"
	_zarpar_boton.pressed.connect(_zarpar)
	caja.add_child(_zarpar_boton)
	var cerrar := Button.new()
	cerrar.text = "Cerrar  [Esc]"
	cerrar.pressed.connect(cerrar_panel)
	caja.add_child(cerrar)
	RastreoCarga.cargamento_atracado.connect(func(_m): _repintar())
	RastreoCarga.carga_descargada.connect(func(_m): _repintar())
	RastreoCarga.informe_interceptacion.connect(_mostrar_interceptacion)
	RastreoCarga.cargamento_perdido.connect(func(_m, _motivo): _repintar())
	Almacen.existencias_cambiadas.connect(func(_id, _cantidad): _actualizar_ruta_info())
	MuelleManager.grua_activada.connect(_actualizar_grua)
	_actualizar_grua()
	_actualizar_ruta_info()

func abrir(estado: String = "abierta") -> void:
	_aviso = ""
	visible = true
	_estacion_abierta = estado == "abierta"
	_estado.text = "Abierto" if estado == "abierta" else "Detenido por la noche"
	_descargar_boton.disabled = estado != "abierta"
	_zarpar_boton.disabled = estado != "abierta"
	_ruta_selector.disabled = estado != "abierta"
	_actualizar_bloqueos(estado == "abierta")
	_actualizar_grua()
	_repintar()

func _activar_grua() -> void:
	if MuelleManager.activar_grua():
		_aviso = "Red de arrastre instalada."
	else:
		_aviso = "Faltan %d tablones tratados y/o %d doblones." % [
			MuelleManager.COSTE_TABLONES, MuelleManager.COSTE_DOBLONES]
	_actualizar_grua()
	_repintar()

func _actualizar_grua() -> void:
	if _grua_boton == null:
		return
	_grua_boton.text = "Red de arrastre instalada" if MuelleManager.grua_activa else \
		"Instalar red (%d tablones, %d doblones)" % [MuelleManager.COSTE_TABLONES, MuelleManager.COSTE_DOBLONES]
	_grua_boton.disabled = MuelleManager.grua_activa or not _estacion_abierta

func cerrar_panel() -> void:
	visible = false
	_aviso = ""

func abierto() -> bool:
	return visible

func _descargar() -> void:
	if _descargar_boton.disabled:
		return
	var n := RastreoCarga.descargar_todo()
	_aviso = "%d cargamento(s) descargado(s)." % n if n > 0 else "No hay cargamentos listos en el puerto."
	_repintar()

func _zarpar() -> void:
	if _zarpar_boton.disabled:
		return
	var id := RastreoCarga.zarpar_ruta(_ruta_id)
	_aviso = "Expedicion %s en el mar." % id if id != "" else "No se pudo zarpar: falta carga o espacio."
	_repintar()

func _mostrar_interceptacion(manifiesto: Dictionary) -> void:
	_interceptado_id = str(manifiesto.get("id", ""))
	_interceptado_info.text = "La Marina intercepto %s. Elige una respuesta." % _interceptado_id
	visible = true
	_estado.text = "Interceptacion: decision requerida"
	_actualizar_bloqueos(true)
	_repintar()

func _decidir_interceptacion(decision: String) -> void:
	if _interceptado_id == "":
		return
	var id := _interceptado_id
	RastreoCarga.resolver_interceptacion(id, decision)
	_aviso = "La carga sigue su ruta." if RastreoCarga.manifiestos.has(id) else "La expedicion se perdio."
	_interceptado_id = ""
	_interceptado_info.visible = false
	_actualizar_bloqueos(true)
	_repintar()

func _actualizar_bloqueos(estacion_abierta: bool) -> void:
	var decision_pendiente := _interceptado_id != ""
	_descargar_boton.disabled = not estacion_abierta or decision_pendiente
	_zarpar_boton.disabled = not estacion_abierta or decision_pendiente
	_ruta_selector.disabled = not estacion_abierta or decision_pendiente
	_mapa_boton.disabled = not estacion_abierta or decision_pendiente
	_interceptado_info.visible = decision_pendiente
	_soltar_boton.visible = decision_pendiente
	_luchar_boton.visible = decision_pendiente

func _actualizar_ruta_info() -> void:
	if _ruta_info == null:
		return
	var r := RastreoCarga.ruta(_ruta_id)
	if r.is_empty():
		_ruta_info.text = "Ruta no disponible."
		return
	var barco := str(r["barco"])
	var cap: Dictionary = RastreoCarga.capacidad(barco)
	var medida: Dictionary = RastreoCarga.medir(r["contenido"], int(r["canones"]))
	var lineas: Array[String] = []
	lineas.append("[ %s ]  ·  %d dias" % [str(r["nombre"]), int(r["dias"])])
	lineas.append("Capacidad: %.0f/%.0f volumen  ·  %.0f/%.0f peso" % [
		float(medida["volumen"]), float(cap["volumen"]), float(medida["peso"]), float(cap["peso"])])
	lineas.append("Canones: %d/%d" % [int(r["canones"]), int(cap["canones_max"])])
	var faltan: Array[String] = []
	for id in r["contenido"]:
		var necesita := int(r["contenido"][id])
		var disponible := Almacen.disponible(str(id))
		lineas.append("%s: %d/%d" % [BaseDeDatos.nombre_item(str(id)), disponible, necesita])
		if disponible < necesita:
			faltan.append("%dx %s" % [necesita - disponible, BaseDeDatos.nombre_item(str(id))])
	var canones_disponibles := Almacen.disponible("canon")
	if canones_disponibles < int(r["canones"]):
		faltan.append("%dx Canon de Cubierta" % [int(r["canones"]) - canones_disponibles])
	lineas.append("Faltan: " + ", ".join(faltan) if not faltan.is_empty() else "Carga lista para zarpar")
	_ruta_info.text = "\n".join(lineas)

func _repintar() -> void:
	if not visible or _lista == null:
		return
	var lineas: Array[String] = []
	var global := RastreoCarga.inventario_global()
	lineas.append("[color=#7d8798]INVENTARIO GLOBAL[/color]")
	for id in global:
		var g: Dictionary = global[id]
		if int(g["mar"]) + int(g["puerto"]) > 0:
			lineas.append("%s  · mar %d · puerto %d · cofres %d" % [
				BaseDeDatos.nombre_item(str(id)), int(g["mar"]), int(g["puerto"]), int(g["cofres"])])
	if RastreoCarga.en_mar().is_empty() and RastreoCarga.en_puerto().is_empty():
		lineas.append("No hay cargamentos en tránsito ni atracados.")
	_lista.text = (_aviso + "\n\n" if _aviso != "" else "") + "\n".join(lineas)

func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		cerrar_panel()
		get_viewport().set_input_as_handled()
