class_name InteriorLayoutEditor
extends Node2D

const TransicionZonaScript := preload("res://scripts/interiores/transicion_zona.gd")
const IsometricCalibratorScript := preload("res://scripts/desarrollador/isometric_calibrator.gd")
const InteriorTemplateManagerScript := preload("res://scripts/desarrollador/interior_template_manager.gd")

enum ModoEditor { BASE, OBJETOS }
enum ModoAjuste { LIBRE, PIXEL, SUBREJILLA, MEDIA_BALDOSA, BALDOSA }
## Editor visual local para comparador_herreria.tscn.
##
## Edita transformaciones visuales por instancia sin tocar la definicion del
## interior, su transitabilidad ni los datos de produccion. Los nodos editables
## reciben layout_id/layout_base_position desde InteriorEscena.

const RUTA_LAYOUT := "res://data/desarrollador/interiores/interior_herreria_pb_layout.json"
const RUTA_LAYOUT_RESPALDO := RUTA_LAYOUT + ".bak"
const RUTA_LAYOUT_AUTOSALVADO := RUTA_LAYOUT + ".autosave"

var interior: InteriorEscena = null
var referencia: Node2D = null
var colocador: Node = null

var _elementos: Dictionary = {}
var _orden_ids: Array[String] = []
var _seleccionado: Node2D = null
var _seleccionados: Array[Node2D] = []
var _calibrador = null
var _arrastrando := false
var _arrastre_offset := Vector2.ZERO
var _arrastre_offsets: Dictionary = {}
var _seleccionando_marco := false
var _marco_inicio := Vector2.ZERO
var _marco_actual := Vector2.ZERO
var _seleccionando_region_colocacion := false
var _region_colocacion_inicio := Vector2.ZERO
var _region_colocacion_actual := Vector2.ZERO
var _modo_relleno_muro := false
var _seleccionando_relleno_muro := false
var _relleno_muro_inicio := Vector2.ZERO
var _relleno_muro_actual := Vector2.ZERO
var _mostrar_rejilla := false
var _mostrar_subrejilla := true
# La rejilla de muros inicia visible para que cada segmento pueda alinearse
# con las aristas del suelo desde el primer momento en el editor.
# W la alterna sin afectar al interior jugable.
var _mostrar_rejilla_muros := true
var _mostrar_assets_muros := false
var _mostrar_transitable := false
var _mostrar_guias := true
var _mostrar_colisiones := false
var _mostrar_capas := false
var _vista_limpia := false
var _modo_ajuste := ModoAjuste.LIBRE
var _capas_bloqueadas: Dictionary = {"base": false, "objetos": false}
var _capas_visibles: Dictionary = {"base": true, "objetos": true, "transiciones": true}
var _portapapeles_layout: Array[Dictionary] = []
var _diagnostico_label: Label
var _problemas_editor: Array[String] = []
var _plantilla_nombre := "herreria_aprobada"

# Jerarquía visual de la rejilla del editor:
# gris = rejilla, verde/rojo = transitabilidad, verde = hover,
# dorado = selección y límite de sala. Evita que varias guías parezcan
# colores aleatorios de la misma baldosa.
const COLOR_REJILLA_EDITOR := Color("#5e5e73", 0.72)
const COLOR_SUBREJILLA_EDITOR := Color("#8b8b9e", 0.42)
const COLOR_TRANSITABLE_EDITOR := Color("#4a804d", 0.18)
const COLOR_BLOQUEADO_EDITOR := Color("#bd403a", 0.20)
const ALTURA_REJILLA_MURO_FISICA := 128.0
var _modo_colocacion := false
var _historial: Array[Dictionary] = []
var _historial_indice := -1
var _zoom_sala := 0.50
var _zoom_referencia := 0.31
const ZOOM_SALA_MIN := 0.35
const ZOOM_SALA_MAX := 0.85
const ZOOM_REFERENCIA_MIN := 0.20
const ZOOM_REFERENCIA_MAX := 0.60
const TAMANO_MINIMO := 3
var _ancho_editor := TAMANO_MINIMO
var _alto_editor := TAMANO_MINIMO

var _panel: PanelContainer
var _panel_comandos: PanelContainer
var _boton_panel: Button
var _boton_comandos: Button
var _boton_paleta: Button
var _boton_referencia_flecha: Button
var _boton_mover_panel: Button
var _boton_mover_comandos: Button
var _boton_mover_paleta: Button
var _boton_mover_referencia: Button
var _panel_expandido := true
var _comandos_expandidos := true
var _paleta_expandida := true
var _referencia_expandida := true
var _panel_arrastrado: Control = null
var _panel_arrastre_inicio := Vector2.ZERO
var _panel_pos_inicio := Vector2.ZERO
var _ui_arrastrando := ""
var _ui_arrastre_inicio := Vector2.ZERO
var _ui_pos_inicio := Vector2.ZERO
var _estado: Label
var _elemento: Label
var _offset_x: SpinBox
var _offset_y: SpinBox
var _cal_offset_x: SpinBox
var _cal_offset_y: SpinBox
var _cal_escala_x: SpinBox
var _cal_escala_y: SpinBox
var _cal_skew: SpinBox
var _cal_rotacion: SpinBox
var _altura_muro_label: Label
var _altura_muro_spin: SpinBox
var _rotacion: Label
var _zoom_sala_label: Label
var _zoom_referencia_label: Label
var _tamano_editor_label: Label
var _transicion_info: Label
var _destino_zona_edit: LineEdit
var _entrada_destino_x: SpinBox
var _entrada_destino_y: SpinBox
var _accion_transicion_edit: LineEdit
var _boton_quitar_transicion: Button
var _hovered: Node2D = null
var _hover_muro_casilla := Vector2i(-1, -1)
var _hover_muro_eje := ""
var _paleta: PanelContainer
var _paleta_categoria: Label
var _paleta_slots: HBoxContainer
var _paleta_busqueda: LineEdit
var _paleta_pagina: Label
var _boton_paleta_anterior: Button
var _boton_paleta_siguiente: Button
var _boton_relleno_muro_paleta: Button
var _categoria_actual := 0
var _slot_claves: Array[String] = []
const CATEGORIAS: Array[String] = ["MUROS", "SUELOS", "MOBILIARIO", "PUERTAS / ESCALERAS"]
const SLOTS_POR_PAGINA := 6
var _pagina_paleta := 0
var _paneando_sala := false
var _paneando_referencia := false
var _paneo_mouse_inicio := Vector2.ZERO
var _paneo_pos_inicio := Vector2.ZERO
var _gizmo_arrastrando := false
var _gizmo_manejador := ""
var _gizmo_mouse_inicio := Vector2.ZERO
var _gizmo_rect_inicio := Rect2()
var _gizmo_ajustes_inicio: Dictionary = {}
var _asset_activo := ""
var _asset_preview: Node2D = null
var _colocando_asset := false
var _arrastrando_asset := false
var _siguiente_asset_id := 1
var _modo_editor := ModoEditor.BASE
var _modo_editor_label: Label
var _boton_modo_editor: Button
var _boton_referencia: Button
var _boton_borrar_base: Button
var _boton_borrar_objetos: Button
var _boton_lienzo_vacio: Button
var _boton_bloquear_base: Button
var _boton_bloquear_objetos: Button
var _boton_relleno_muro: Button
var _boton_assets_muros: Button
var _boton_visibilidad_base: Button
var _boton_visibilidad_objetos: Button
var _boton_visibilidad_transiciones: Button
var _boton_modo_ajuste: Button
var _confirmacion_borrado: ConfirmationDialog
var _modo_borrado_pendiente := ModoEditor.BASE
# El comparador comienza como lienzo de trabajo limpio. Es una ocultación
# reversible: la definición jugable y el layout guardado no se eliminan.
var _base_oculta_por_boton := false
var _objetos_ocultos_por_boton := false
var _rejilla_muros_antes_borrado := true
var _rejilla_suelo_antes_borrado := false
var _subrejilla_suelo_antes_borrado := true
var _botones_categorias: Array[Button] = []
var _referencia_visible := true
var _tamano_viewport_editor := Vector2.ZERO
var _paleta_posicionada_manualmente := false

func _ready() -> void:
	call_deferred("_inicializar")

func _inicializar() -> void:
	if interior != null and interior.definicion != null:
		_ancho_editor = maxi(TAMANO_MINIMO, interior.definicion.ancho)
		_alto_editor = maxi(TAMANO_MINIMO, interior.definicion.alto)
	_indexar_elementos()
	_calibrador = IsometricCalibratorScript.new()
	_calibrador.name = "CalibradorIso"
	_calibrador.z_index = 100
	_calibrador.visible = false
	add_child(_calibrador)
	_crear_panel()
	_cargar_layout(false)
	_aplicar_tamano_visual()
	_guardar_historial()
	queue_redraw()

func _process(_delta: float) -> void:
	_actualizar_hover()
	_actualizar_preview_asset()
	_ajustar_paleta_al_viewport()
	_actualizar_manejadores_ui()
	queue_redraw()
	_actualizar_panel()

func _input(event: InputEvent) -> void:
	if _gestionar_arrastre_ui(event):
		return
	if _gestionar_arrastre_paleta(event):
		return
	# Los controles de la interfaz tienen prioridad sobre el canvas. Sin esta
	# guarda, el editor consume el clic antes de que Button emita pressed.
	if event is InputEventMouse and _mouse_sobre_interfaz(event.position):
		return
	if _modo_colocacion:
		# BuildManager recibe los eventos en _unhandled_input.
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
			_modo_colocacion = false
			if colocador != null:
				colocador.process_mode = Node.PROCESS_MODE_DISABLED
			_actualizar_estado("Editor visual activo")
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			_modo_colocacion = true
			if colocador != null:
				colocador.process_mode = Node.PROCESS_MODE_INHERIT
			_actualizar_estado("Modo colocacion activo. Pulsa B para volver al editor")
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.keycode == KEY_S:
			_guardar_layout()
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.keycode == KEY_O:
			_cargar_layout(true)
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.keycode == KEY_Z:
			_deshacer()
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.keycode == KEY_Y:
			_rehacer()
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_H:
			_alinear_seleccion(true)
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_V:
			_alinear_seleccion(false)
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.keycode == KEY_C:
			_copiar_seleccion()
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.keycode == KEY_V:
			_pegar_seleccion()
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.keycode == KEY_D:
			_duplicar_seleccion()
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_S:
			_guardar_plantilla()
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_O:
			_cargar_plantilla()
			get_viewport().set_input_as_handled()
			return
		match event.keycode:
			KEY_G: _mostrar_rejilla = not _mostrar_rejilla
			KEY_V: _mostrar_subrejilla = not _mostrar_subrejilla
			KEY_W: _alternar_rejilla_muros()
			KEY_T: _mostrar_transitable = not _mostrar_transitable
			KEY_H: _mostrar_guias = not _mostrar_guias
			KEY_C: _mostrar_colisiones = not _mostrar_colisiones
			KEY_L: _mostrar_capas = not _mostrar_capas
			KEY_N: _ciclar_modo_ajuste()
			KEY_M: _alternar_modo_relleno_muro()
			KEY_F5: _alternar_vista_limpia()
			KEY_F2: _alternar_referencia()
			KEY_R: _espejar_horizontal_seleccionado()
			KEY_F: _voltear_seleccionado()
			KEY_U: _restaurar_seleccionado()
			KEY_I: _alternar_guia_calibracion()
			KEY_K: _restaurar_calibracion_seleccionada()
			KEY_BRACKETLEFT: _cambiar_asset(-1)
			KEY_BRACKETRIGHT: _cambiar_asset(1)
			KEY_DELETE: _ocultar_seleccionado()
			KEY_Q: _seleccion_anterior()
			KEY_E: _seleccion_siguiente()
			KEY_ESCAPE:
				_cancelar_arrastre_gizmo()
				_cancelar_asset_activo()
				_cancelar_arrastre()
				_seleccionando_marco = false
				_seleccionando_relleno_muro = false
				_limpiar_seleccion()
			_: _mover_con_teclado(event)
		get_viewport().set_input_as_handled()
		queue_redraw()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var factor := 0.05 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.05
			if event.position.x < 650.0:
				_ajustar_zoom_sala(factor)
			else:
				_ajustar_zoom_referencia(factor)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			_iniciar_paneo(event.position)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
			_paneando_sala = false
			_paneando_referencia = false
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _gestionar_clic_celda_muro(event.position):
					get_viewport().set_input_as_handled()
					return
				if _iniciar_arrastre_gizmo(event.position):
					get_viewport().set_input_as_handled()
					return
				if _colocando_asset and _cursor_en_sala():
					_arrastrando_asset = true
					_actualizar_preview_asset()
				elif _cursor_sobre_referencia():
					_iniciar_paneo_referencia()
				else:
					var bajo := _elemento_bajo_cursor()
					if bajo != null:
						_seleccionar_bajo_cursor(bajo)
					else:
						_iniciar_paneo_sala()
			else:
				if _gizmo_arrastrando:
					_finalizar_arrastre_gizmo()
					get_viewport().set_input_as_handled()
					return
				if _arrastrando_asset:
					_colocar_asset_activo()
				_arrastrando_asset = false
				_arrastrando = false
				_confirmar_posicion_transiciones()
				_paneando_sala = false
				_paneando_referencia = false
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if _modo_relleno_muro and _asset_activo != "" and _cursor_en_sala():
					_iniciar_relleno_muro(event.position)
				elif _colocando_asset and _cursor_en_sala():
					_iniciar_region_colocacion(event.position)
				elif _colocando_asset:
					_cancelar_asset_activo()
				elif _cursor_en_sala():
					_iniciar_marco_seleccion(event.position)
				else:
					_cancelar_arrastre()
			else:
				if _seleccionando_relleno_muro:
					_finalizar_relleno_muro()
				elif _seleccionando_region_colocacion:
					_finalizar_region_colocacion()
				elif _seleccionando_marco:
					_finalizar_marco_seleccion()
				else:
					_cancelar_arrastre()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion:
		if _gizmo_arrastrando:
			_actualizar_arrastre_gizmo()
			get_viewport().set_input_as_handled()
			return
		if _paneando_sala and interior != null:
			interior.position = _paneo_pos_inicio + (event.position - _paneo_mouse_inicio)
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if _paneando_referencia and referencia != null:
			referencia.position = _paneo_pos_inicio + (event.position - _paneo_mouse_inicio)
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if _arrastrando and _seleccionado != null:
			var mouse := get_global_mouse_position()
			for nodo in _seleccionados:
				if nodo != null and is_instance_valid(nodo):
					var destino: Vector2 = mouse + _arrastre_offsets.get(str(nodo.get_meta("layout_id", "")), _arrastre_offset)
					nodo.global_position = _ajustar_posicion_para_nodo(nodo, destino)
			_actualizar_panel()
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if _seleccionando_marco:
			_marco_actual = event.position
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if _seleccionando_region_colocacion:
			_region_colocacion_actual = event.position
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if _seleccionando_relleno_muro:
			_relleno_muro_actual = event.position
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if _arrastrando_asset:
			_actualizar_preview_asset()
			get_viewport().set_input_as_handled()

func _indexar_elementos() -> void:
	_elementos.clear()
	_orden_ids.clear()
	if interior == null:
		return
	_indexar_nodo(interior)
	_orden_ids.sort()

func _es_editable_en_modo(nodo: Node2D) -> bool:
	if nodo == null or not is_instance_valid(nodo):
		return false
	if not _capa_visible_para_editor(nodo):
		return false
	var rol := str(nodo.get_meta("layout_role", ""))
	if _modo_editor == ModoEditor.BASE:
		return (rol == "suelo" or rol == "muro" or rol == "borde") and not _capas_bloqueadas["base"]
	return (rol == "mueble" or rol == "transicion") and not _capas_bloqueadas["objetos"]

func _capa_de_nodo(nodo: Node2D) -> String:
	var rol := str(nodo.get_meta("layout_role", ""))
	if rol == "transicion":
		return "transiciones"
	return "base" if rol in ["suelo", "muro", "borde"] else "objetos"

func _capa_visible_para_editor(nodo: Node2D) -> bool:
	if nodo == null or not is_instance_valid(nodo):
		return false
	var rol := str(nodo.get_meta("layout_role", ""))
	return bool(_capas_visibles.get(_capa_de_nodo(nodo), true))

func _alternar_assets_muros() -> void:
	_mostrar_assets_muros = not _mostrar_assets_muros
	_actualizar_visibilidad_capas()
	_actualizar_botones_herramientas()
	_actualizar_estado("Assets de muros: %s" % ("ON" if _mostrar_assets_muros else "OFF"))
	queue_redraw()

func _alternar_lienzo_vacio() -> void:
	if _base_oculta_por_boton and _objetos_ocultos_por_boton:
		_restaurar_todo_modo(ModoEditor.BASE)
		_restaurar_todo_modo(ModoEditor.OBJETOS)
		_actualizar_estado("Lienzo restaurado. Assets visibles.")
	else:
		_aplicar_borrado_modo(ModoEditor.BASE)
		_aplicar_borrado_modo(ModoEditor.OBJETOS)
		_actualizar_estado("Lienzo vacío. Puedes colocar assets desde la paleta.")
	_actualizar_visibilidad_capas()
	_actualizar_botones_herramientas()
	queue_redraw()

func _alternar_visibilidad_capa(capa: String) -> void:
	_capas_visibles[capa] = not bool(_capas_visibles.get(capa, true))
	if _seleccionado != null and not _capa_visible_para_editor(_seleccionado):
		_limpiar_seleccion(false)
	_actualizar_visibilidad_capas()
	_actualizar_botones_capas()
	_actualizar_estado("Capa %s %s" % [capa, "visible" if _capas_visibles[capa] else "oculta"])
	queue_redraw()

func _actualizar_visibilidad_capas() -> void:
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo):
			continue
		var capa := _capa_de_nodo(nodo)
		# La visibilidad de capa es solo de presentación. No modifica la huella,
		# la transitabilidad ni el estado guardable del elemento.
		var visible := bool(_capas_visibles.get(capa, true))
		var rol := str(nodo.get_meta("layout_role", ""))
		if capa == "base" and _base_oculta_por_boton:
			visible = false
		if capa == "objetos" and _objetos_ocultos_por_boton:
			visible = false
		if rol in ["muro", "borde"]:
			visible = visible and _mostrar_assets_muros
		nodo.self_modulate = Color(1.0, 1.0, 1.0, 1.0 if visible else 0.0)

func _actualizar_botones_capas() -> void:
	if _boton_visibilidad_base != null:
		_boton_visibilidad_base.text = ("BASE: ON" if _capas_visibles["base"] else "BASE: OFF")
	if _boton_visibilidad_objetos != null:
		_boton_visibilidad_objetos.text = ("OBJETOS: ON" if _capas_visibles["objetos"] else "OBJETOS: OFF")
	if _boton_visibilidad_transiciones != null:
		_boton_visibilidad_transiciones.text = ("TRANS.: ON" if _capas_visibles["transiciones"] else "TRANS.: OFF")

func _alternar_bloqueo(capa: String) -> void:
	_capas_bloqueadas[capa] = not bool(_capas_bloqueadas.get(capa, false))
	if _capas_bloqueadas[capa] and _seleccionado != null and _capa_de_nodo(_seleccionado) == capa:
		_limpiar_seleccion(false)
	_actualizar_botones_herramientas()
	_actualizar_estado("Capa %s %s" % [capa, "bloqueada" if _capas_bloqueadas[capa] else "desbloqueada"])
	queue_redraw()

func _crear_boton_herramienta(contenedor: Container, texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(66, 23)
	boton.add_theme_font_size_override("font_size", 8)
	boton.pressed.connect(accion)
	contenedor.add_child(boton)

func _actualizar_botones_herramientas() -> void:
	if _boton_bloquear_base != null:
		_boton_bloquear_base.text = ("DESBLOQ. BASE" if _capas_bloqueadas["base"] else "BLOQUEAR BASE")
	if _boton_bloquear_objetos != null:
		_boton_bloquear_objetos.text = ("DESBLOQ. OBJETOS" if _capas_bloqueadas["objetos"] else "BLOQUEAR OBJETOS")
	if _boton_modo_ajuste != null:
		var nombres := ["AJUSTE: LIBRE", "AJUSTE: PIXEL", "AJUSTE: 2x2", "AJUSTE: 1/2", "AJUSTE: TILE"]
		_boton_modo_ajuste.text = nombres[_modo_ajuste]
	if _boton_assets_muros != null:
		_boton_assets_muros.text = "ASSETS MUROS: ON" if _mostrar_assets_muros else "ASSETS MUROS: OFF"
	if _boton_lienzo_vacio != null:
		_boton_lienzo_vacio.text = "RESTAURAR LIENZO" if (_base_oculta_por_boton and _objetos_ocultos_por_boton) else "LIENZO VACÍO"

func _ciclar_modo_ajuste() -> void:
	_modo_ajuste = posmod(_modo_ajuste + 1, ModoAjuste.size())
	var nombres := ["LIBRE", "PIXEL", "SUBREJILLA", "MEDIA BALDOSA", "BALDOSA"]
	_actualizar_estado("Ajuste: %s" % nombres[_modo_ajuste])

func _ajustar_posicion(posicion: Vector2) -> Vector2:
	if _modo_ajuste == ModoAjuste.LIBRE:
		return posicion
	if interior == null or not is_instance_valid(interior):
		return posicion
	var local := interior.to_local(posicion)
	match _modo_ajuste:
		ModoAjuste.PIXEL:
			local = Vector2(roundf(local.x), roundf(local.y))
		ModoAjuste.SUBREJILLA:
			local = Vector2(roundf(local.x / 32.0) * 32.0, roundf(local.y / 16.0) * 16.0)
		ModoAjuste.MEDIA_BALDOSA:
			local = Vector2(roundf(local.x / 64.0) * 64.0, roundf(local.y / 32.0) * 32.0)
		ModoAjuste.BALDOSA:
			local = Iso.centro_v(Iso.a_tile(local))
	return interior.to_global(local)

func _alternar_rejilla_muros() -> void:
	_mostrar_rejilla_muros = not _mostrar_rejilla_muros
	_actualizar_estado("Rejilla de muros: %s" % ("ON" if _mostrar_rejilla_muros else "OFF"))
	queue_redraw()

func _ajustar_posicion_para_nodo(nodo: Node2D, posicion: Vector2) -> Vector2:
	if nodo != null and is_instance_valid(nodo) and _es_muro_o_borde(nodo):
		var casilla := Iso.a_tile(interior.to_local(posicion))
		return _posicion_muro_global(casilla, str(nodo.get_meta("layout_asset", "")))
	return _ajustar_posicion(posicion)

func _nombre_modo_editor() -> String:
	return "BASE · MUROS Y SUELOS" if _modo_editor == ModoEditor.BASE else "OBJETOS · MUEBLES Y TRANSICIONES"

func _actualizar_modo_editor() -> void:
	if _modo_editor == ModoEditor.BASE and _categoria_actual > 1:
		_categoria_actual = 0
	elif _modo_editor == ModoEditor.OBJETOS and _categoria_actual < 2:
		_categoria_actual = 2
	if _modo_editor == ModoEditor.OBJETOS and _modo_relleno_muro:
		_modo_relleno_muro = false
		_seleccionando_relleno_muro = false
	if _modo_editor_label != null:
		_modo_editor_label.text = "MODO ACTIVO: %s" % _nombre_modo_editor()
	if _boton_modo_editor != null:
		_boton_modo_editor.text = "VALIDAR BASE → EDITAR OBJETOS" if _modo_editor == ModoEditor.BASE else "VOLVER A EDITAR BASE"
	if _boton_referencia != null:
		_boton_referencia.text = "▼ OCULTAR REFERENCIA" if _referencia_visible else "▶ MOSTRAR REFERENCIA"
	if _boton_borrar_base != null:
		_boton_borrar_base.disabled = _modo_editor != ModoEditor.BASE
		_boton_borrar_base.text = "RESTAURAR BASE" if _base_oculta_por_boton else "BORRAR BASE"
	if _boton_borrar_objetos != null:
		_boton_borrar_objetos.disabled = _modo_editor != ModoEditor.OBJETOS
		_boton_borrar_objetos.text = "RESTAURAR OBJETOS" if _objetos_ocultos_por_boton else "BORRAR OBJETOS"
	if _boton_relleno_muro != null:
		_boton_relleno_muro.disabled = _modo_editor != ModoEditor.BASE
		_boton_relleno_muro.text = "RELLENAR MURO: ON" if _modo_relleno_muro else "RELLENAR MURO: OFF"
	if _boton_relleno_muro_paleta != null:
		_boton_relleno_muro_paleta.disabled = _modo_editor != ModoEditor.BASE
		_boton_relleno_muro_paleta.text = "RELLENAR MURO [M]: ON" if _modo_relleno_muro else "RELLENAR MURO [M]: OFF"
	_actualizar_botones_herramientas()
	for i in _botones_categorias.size():
		_botones_categorias[i].disabled = (_modo_editor == ModoEditor.BASE and i > 1) or (_modo_editor == ModoEditor.OBJETOS and i < 2)
	_limpiar_seleccion(false)
	_hovered = null
	_actualizar_paleta()
	_actualizar_estado("Modo %s" % _nombre_modo_editor())
	queue_redraw()

func _validar_base_y_cambiar_modo() -> void:
	if _modo_editor == ModoEditor.BASE:
		var pisos := 0
		var muros := 0
		for id in _orden_ids:
			var nodo: Node2D = _elementos.get(id)
			if nodo == null or not is_instance_valid(nodo):
				continue
			var rol := str(nodo.get_meta("layout_role", ""))
			if rol == "suelo":
				pisos += 1
			elif rol == "muro":
				muros += 1
		_modo_editor = ModoEditor.OBJETOS
		_actualizar_modo_editor()
		_actualizar_estado("Base validada: %d pisos y %d muros. Ahora puedes editar objetos." % [pisos, muros])
	else:
		_modo_editor = ModoEditor.BASE
		_actualizar_modo_editor()

func _indexar_nodo(nodo: Node) -> void:
	if nodo.has_meta("layout_id") and nodo is Node2D:
		var id := str(nodo.get_meta("layout_id"))
		if id != "":
			_elementos[id] = nodo
			_orden_ids.append(id)
	for hijo in nodo.get_children():
		_indexar_nodo(hijo)

func _crear_panel() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 200
	add_child(capa)
	_panel = PanelContainer.new()
	_panel.position = Vector2(18, 18)
	_panel.custom_minimum_size = Vector2(270, 0)
	_panel.size = Vector2(270, 560)
	_panel.add_theme_stylebox_override("panel", _estilo_panel(Color("#172238"), GlobalColors.get_color_interaccion(), 2, 0.94))
	capa.add_child(_panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	_panel.add_child(columna)
	var titulo := Label.new()
	titulo.text = "EDITOR DE INTERIORES"
	titulo.add_theme_font_size_override("font_size", 15)
	titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	columna.add_child(titulo)
	_modo_editor_label = Label.new()
	_modo_editor_label.add_theme_font_size_override("font_size", 11)
	_modo_editor_label.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	columna.add_child(_modo_editor_label)
	_boton_modo_editor = Button.new()
	_boton_modo_editor.custom_minimum_size = Vector2(220, 26)
	_boton_modo_editor.add_theme_font_size_override("font_size", 10)
	_boton_modo_editor.pressed.connect(_validar_base_y_cambiar_modo)
	columna.add_child(_boton_modo_editor)
	_boton_referencia = Button.new()
	_boton_referencia.custom_minimum_size = Vector2(220, 24)
	_boton_referencia.add_theme_font_size_override("font_size", 10)
	_boton_referencia.pressed.connect(_alternar_referencia)
	columna.add_child(_boton_referencia)
	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 4)
	columna.add_child(acciones)
	_boton_borrar_base = Button.new()
	_boton_borrar_base.text = "BORRAR BASE"
	_boton_borrar_base.custom_minimum_size = Vector2(126, 24)
	_boton_borrar_base.add_theme_font_size_override("font_size", 9)
	_boton_borrar_base.tooltip_text = "Oculta todos los suelos y muros del editor"
	_boton_borrar_base.pressed.connect(_pedir_borrado_modo.bind(ModoEditor.BASE))
	acciones.add_child(_boton_borrar_base)
	_boton_borrar_objetos = Button.new()
	_boton_borrar_objetos.text = "BORRAR OBJETOS"
	_boton_borrar_objetos.custom_minimum_size = Vector2(126, 24)
	_boton_borrar_objetos.add_theme_font_size_override("font_size", 9)
	_boton_borrar_objetos.tooltip_text = "Oculta todos los muebles y transiciones del editor"
	_boton_borrar_objetos.pressed.connect(_pedir_borrado_modo.bind(ModoEditor.OBJETOS))
	acciones.add_child(_boton_borrar_objetos)
	_boton_lienzo_vacio = Button.new()
	_boton_lienzo_vacio.custom_minimum_size = Vector2(256, 24)
	_boton_lienzo_vacio.add_theme_font_size_override("font_size", 9)
	_boton_lienzo_vacio.tooltip_text = "Oculta o restaura pisos, muros y objetos sin borrar datos"
	_boton_lienzo_vacio.pressed.connect(_alternar_lienzo_vacio)
	columna.add_child(_boton_lienzo_vacio)
	var acciones_capa := HBoxContainer.new()
	acciones_capa.add_theme_constant_override("separation", 4)
	columna.add_child(acciones_capa)
	_boton_bloquear_base = Button.new()
	_boton_bloquear_base.custom_minimum_size = Vector2(126, 24)
	_boton_bloquear_base.add_theme_font_size_override("font_size", 9)
	_boton_bloquear_base.pressed.connect(_alternar_bloqueo.bind("base"))
	acciones_capa.add_child(_boton_bloquear_base)
	_boton_bloquear_objetos = Button.new()
	_boton_bloquear_objetos.custom_minimum_size = Vector2(126, 24)
	_boton_bloquear_objetos.add_theme_font_size_override("font_size", 9)
	_boton_bloquear_objetos.pressed.connect(_alternar_bloqueo.bind("objetos"))
	acciones_capa.add_child(_boton_bloquear_objetos)
	var visibilidad_capa := HBoxContainer.new()
	visibilidad_capa.add_theme_constant_override("separation", 3)
	columna.add_child(visibilidad_capa)
	_boton_visibilidad_base = _crear_boton_capa(visibilidad_capa, "BASE: ON", "base")
	_boton_visibilidad_objetos = _crear_boton_capa(visibilidad_capa, "OBJETOS: ON", "objetos")
	_boton_visibilidad_transiciones = _crear_boton_capa(visibilidad_capa, "TRANS.: ON", "transiciones")
	var herramientas := HBoxContainer.new()
	herramientas.add_theme_constant_override("separation", 3)
	columna.add_child(herramientas)
	_crear_boton_herramienta(herramientas, "COPIAR", _copiar_seleccion)
	_crear_boton_herramienta(herramientas, "PEGAR", _pegar_seleccion)
	_crear_boton_herramienta(herramientas, "DUPLICAR", _duplicar_seleccion)
	_crear_boton_herramienta(herramientas, "VALIDAR", _validar_editor)
	_crear_boton_herramienta(herramientas, "REST. BAK", _recuperar_respaldo)
	var plantillas := HBoxContainer.new()
	plantillas.add_theme_constant_override("separation", 3)
	columna.add_child(plantillas)
	_crear_boton_herramienta(plantillas, "GUARDAR TPL", _guardar_plantilla)
	_crear_boton_herramienta(plantillas, "CARGAR TPL", _cargar_plantilla)
	_boton_modo_ajuste = Button.new()
	_boton_modo_ajuste.custom_minimum_size = Vector2(92, 23)
	_boton_modo_ajuste.add_theme_font_size_override("font_size", 8)
	_boton_modo_ajuste.pressed.connect(_ciclar_modo_ajuste)
	herramientas.add_child(_boton_modo_ajuste)
	var alineacion := HBoxContainer.new()
	alineacion.add_theme_constant_override("separation", 3)
	columna.add_child(alineacion)
	_crear_boton_herramienta(alineacion, "ALINEAR X", _alinear_seleccion.bind(true))
	_crear_boton_herramienta(alineacion, "ALINEAR Y", _alinear_seleccion.bind(false))
	_crear_boton_herramienta(alineacion, "REALINEAR MUROS", _realinear_muros)
	_crear_boton_herramienta(alineacion, "CORREGIR EJES", _corregir_ejes_muros)
	_boton_relleno_muro = Button.new()
	_boton_relleno_muro.text = "RELLENAR MURO: OFF"
	_boton_relleno_muro.custom_minimum_size = Vector2(150, 23)
	_boton_relleno_muro.add_theme_font_size_override("font_size", 8)
	_boton_relleno_muro.tooltip_text = "Dibuja un rectangulo y genera un perimetro de muros alineado a Iso"
	_boton_relleno_muro.pressed.connect(_alternar_modo_relleno_muro)
	columna.add_child(_boton_relleno_muro)
	var herramientas_muros := HBoxContainer.new()
	herramientas_muros.add_theme_constant_override("separation", 3)
	columna.add_child(herramientas_muros)
	_boton_assets_muros = Button.new()
	_boton_assets_muros.custom_minimum_size = Vector2(112, 23)
	_boton_assets_muros.add_theme_font_size_override("font_size", 8)
	_boton_assets_muros.tooltip_text = "Oculta o muestra los sprites de muro sin borrar la base ni la rejilla"
	_boton_assets_muros.pressed.connect(_alternar_assets_muros)
	herramientas_muros.add_child(_boton_assets_muros)
	_crear_boton_herramienta(herramientas_muros, "REJILLA [W]", _alternar_rejilla_muros)
	_diagnostico_label = Label.new()
	_diagnostico_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_diagnostico_label.custom_minimum_size = Vector2(0, 28)
	_diagnostico_label.add_theme_font_size_override("font_size", 9)
	_diagnostico_label.add_theme_color_override("font_color", GlobalColors.PALETA["plata_salitre"])
	_diagnostico_label.text = "VALIDADOR: pulsa VALIDAR"
	columna.add_child(_diagnostico_label)
	_tamano_editor_label = Label.new()
	_tamano_editor_label.add_theme_font_size_override("font_size", 10)
	_tamano_editor_label.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	columna.add_child(_tamano_editor_label)
	var controles_tamano := HBoxContainer.new()
	controles_tamano.add_theme_constant_override("separation", 3)
	columna.add_child(controles_tamano)
	_crear_boton_tamano(controles_tamano, "−An", -1, 0)
	_crear_boton_tamano(controles_tamano, "+An", 1, 0)
	_crear_boton_tamano(controles_tamano, "−Al", 0, -1)
	_crear_boton_tamano(controles_tamano, "+Al", 0, 1)
	var fila_altura_muro := HBoxContainer.new()
	_altura_muro_label = Label.new()
	_altura_muro_label.text = "Altura muro"
	_altura_muro_label.custom_minimum_size = Vector2(82, 0)
	fila_altura_muro.add_child(_altura_muro_label)
	_altura_muro_spin = SpinBox.new()
	_altura_muro_spin.min_value = 1
	_altura_muro_spin.max_value = 4
	_altura_muro_spin.step = 1
	_altura_muro_spin.value = 1
	_altura_muro_spin.custom_minimum_size = Vector2(80, 22)
	_altura_muro_spin.tooltip_text = "Niveles de altura visual del muro. No cambia colisiones ni transitabilidad."
	_altura_muro_spin.value_changed.connect(_cambiar_altura_muro)
	_hacer_spin_editable(_altura_muro_spin)
	fila_altura_muro.add_child(_altura_muro_spin)
	columna.add_child(fila_altura_muro)
	# El borrado de base/objetos es reversible y se ejecuta directamente desde
	# los botones. No usamos ConfirmationDialog: en la ejecución embebida de
	# Godot puede dejar una ventana secundaria y hacer parecer que el editor se
	# cerró aunque la escena siga viva.
	_elemento = Label.new()
	_elemento.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_elemento.add_theme_font_size_override("font_size", 12)
	columna.add_child(_elemento)
	var controles := HBoxContainer.new()
	columna.add_child(controles)
	var etiqueta_x := Label.new()
	etiqueta_x.text = "Offset X"
	controles.add_child(etiqueta_x)
	_offset_x = SpinBox.new()
	_offset_x.min_value = -512
	_offset_x.max_value = 512
	_offset_x.step = 1
	_offset_x.value_changed.connect(_cambiar_offset_x)
	_hacer_spin_editable(_offset_x)
	controles.add_child(_offset_x)
	var etiqueta_y := Label.new()
	etiqueta_y.text = "Y"
	controles.add_child(etiqueta_y)
	_offset_y = SpinBox.new()
	_offset_y.min_value = -512
	_offset_y.max_value = 512
	_offset_y.step = 1
	_offset_y.value_changed.connect(_cambiar_offset_y)
	_hacer_spin_editable(_offset_y)
	controles.add_child(_offset_y)
	_rotacion = Label.new()
	_rotacion.add_theme_font_size_override("font_size", 12)
	columna.add_child(_rotacion)
	_crear_controles_calibracion(columna)
	_transicion_info = Label.new()
	_transicion_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_transicion_info.add_theme_font_size_override("font_size", 10)
	_transicion_info.add_theme_color_override("font_color", GlobalColors.PALETA["oro_llama"])
	columna.add_child(_transicion_info)
	var destino_fila := HBoxContainer.new()
	var destino_titulo := Label.new()
	destino_titulo.text = "Destino"
	destino_fila.add_child(destino_titulo)
	_destino_zona_edit = LineEdit.new()
	_destino_zona_edit.custom_minimum_size = Vector2(150, 22)
	_destino_zona_edit.placeholder_text = "interior_sotano"
	_destino_zona_edit.text_submitted.connect(_aplicar_datos_transicion)
	destino_fila.add_child(_destino_zona_edit)
	columna.add_child(destino_fila)
	var entrada_fila := HBoxContainer.new()
	var entrada_titulo := Label.new()
	entrada_titulo.text = "Entrada X/Y"
	entrada_fila.add_child(entrada_titulo)
	_entrada_destino_x = SpinBox.new()
	_entrada_destino_x.min_value = 0
	_entrada_destino_x.max_value = 99
	_entrada_destino_x.step = 1
	_entrada_destino_x.custom_minimum_size = Vector2(54, 22)
	_entrada_destino_x.value_changed.connect(_aplicar_datos_transicion_valor)
	_hacer_spin_editable(_entrada_destino_x)
	entrada_fila.add_child(_entrada_destino_x)
	_entrada_destino_y = SpinBox.new()
	_entrada_destino_y.min_value = 0
	_entrada_destino_y.max_value = 99
	_entrada_destino_y.step = 1
	_entrada_destino_y.custom_minimum_size = Vector2(54, 22)
	_entrada_destino_y.value_changed.connect(_aplicar_datos_transicion_valor)
	_hacer_spin_editable(_entrada_destino_y)
	entrada_fila.add_child(_entrada_destino_y)
	columna.add_child(entrada_fila)
	var accion_fila := HBoxContainer.new()
	var accion_titulo := Label.new()
	accion_titulo.text = "Accion"
	accion_fila.add_child(accion_titulo)
	_accion_transicion_edit = LineEdit.new()
	_accion_transicion_edit.custom_minimum_size = Vector2(180, 22)
	_accion_transicion_edit.placeholder_text = "Subir / Bajar / Entrar"
	_accion_transicion_edit.text_submitted.connect(_aplicar_datos_transicion)
	accion_fila.add_child(_accion_transicion_edit)
	columna.add_child(accion_fila)
	_boton_quitar_transicion = Button.new()
	_boton_quitar_transicion.text = "QUITAR TRANSICIÓN SELECCIONADA"
	_boton_quitar_transicion.custom_minimum_size = Vector2(220, 24)
	_boton_quitar_transicion.add_theme_font_size_override("font_size", 9)
	_boton_quitar_transicion.pressed.connect(_quitar_transicion_seleccionada)
	columna.add_child(_boton_quitar_transicion)
	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.add_theme_color_override("font_color", GlobalColors.PALETA["plata_salitre"])
	columna.add_child(_estado)
	_zoom_sala_label = Label.new()
	_zoom_sala_label.add_theme_font_size_override("font_size", 11)
	_zoom_sala_label.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	columna.add_child(_zoom_sala_label)
	_zoom_referencia_label = Label.new()
	_zoom_referencia_label.add_theme_font_size_override("font_size", 11)
	_zoom_referencia_label.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	columna.add_child(_zoom_referencia_label)
	var ayuda := Label.new()
	ayuda.text = "LMB seleccionar/arrastrar · Flechas 1px · Alt media baldosa · Shift 8px · Ctrl+S guardar · Ctrl+O cargar\nR espejo horizontal · F espejo vertical · U restaurar · [ ] cambiar asset · V subrejilla 2x2 · G rejilla · T transitabilidad · C colisiones · B colocacion · F5 vista limpia"
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.add_theme_font_size_override("font_size", 11)
	ayuda.add_theme_color_override("font_color", GlobalColors.PALETA["plata_salitre"])
	columna.add_child(ayuda)
	_panel_comandos = PanelContainer.new()
	_panel_comandos.position = Vector2(820, 530)
	_panel_comandos.custom_minimum_size = Vector2(440, 220)
	_panel_comandos.size = Vector2(440, 220)
	_panel_comandos.add_theme_stylebox_override("panel", _estilo_panel(Color("#30241b"), GlobalColors.get_color_interaccion(), 2, 0.96))
	capa.add_child(_panel_comandos)
	_boton_mover_panel = _crear_boton_mover("Arrastrar panel del editor")
	capa.add_child(_boton_mover_panel)
	_boton_mover_comandos = _crear_boton_mover("Arrastrar panel de comandos")
	capa.add_child(_boton_mover_comandos)
	_boton_mover_referencia = _crear_boton_mover("Arrastrar referencia visual")
	capa.add_child(_boton_mover_referencia)
	_boton_panel = _crear_boton_flecha(Vector2(260, 20))
	_boton_panel.pressed.connect(_alternar_panel_editor)
	capa.add_child(_boton_panel)
	_boton_comandos = _crear_boton_flecha(Vector2(1250, 530))
	_boton_comandos.pressed.connect(_alternar_panel_comandos)
	capa.add_child(_boton_comandos)
	var comandos_columna := VBoxContainer.new()
	comandos_columna.add_theme_constant_override("separation", 3)
	_panel_comandos.add_child(comandos_columna)
	var comandos_titulo := Label.new()
	comandos_titulo.text = "COMANDOS DEL EDITOR"
	comandos_titulo.add_theme_font_size_override("font_size", 15)
	comandos_titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	comandos_columna.add_child(comandos_titulo)
	var comandos_1 := Label.new()
	comandos_1.text = "LMB: seleccionar/mover  |  RMB: cancelar"
	comandos_1.clip_text = true
	comandos_1.add_theme_font_size_override("font_size", 11)
	comandos_1.text = "LMB seleccionar/mover    ·    RMB cancelar"
	comandos_columna.add_child(comandos_1)
	var comandos_2 := Label.new()
	comandos_2.text = "Flechas: 1 px  |  Shift: 8 px  |  Ctrl: 1 tile"
	comandos_2.clip_text = true
	comandos_2.add_theme_font_size_override("font_size", 11)
	comandos_2.text = "Flechas 1 px    ·    Shift 8 px    ·    Ctrl 1 tile"
	comandos_columna.add_child(comandos_2)
	var comandos_3 := Label.new()
	comandos_3.text = "R: espejo horizontal  |  F: espejo vertical  |  U: restaurar  |  [ ]: asset"
	comandos_3.clip_text = true
	comandos_3.add_theme_font_size_override("font_size", 11)
	comandos_3.text = "R rotar    ·    F voltear    ·    U restaurar    ·    [ ] asset"
	comandos_columna.add_child(comandos_3)
	var comandos_4 := Label.new()
	comandos_4.text = "G: rejilla  |  T: transitabilidad  |  C: colisiones  |  L: capas"
	comandos_4.clip_text = true
	comandos_4.add_theme_font_size_override("font_size", 11)
	comandos_4.text = "G rejilla    ·    V subrejilla 2x2    ·    T transitabilidad    ·    C colisiones    ·    L capas"
	comandos_columna.add_child(comandos_4)
	var comandos_5 := Label.new()
	comandos_5.text = "Ctrl+S: guardar  |  Ctrl+O: cargar  |  Ctrl+Z/Y: deshacer"
	comandos_5.clip_text = true
	comandos_5.add_theme_font_size_override("font_size", 11)
	comandos_5.text = "Ctrl+S guardar    ·    Ctrl+O cargar    ·    Ctrl+Z/Y deshacer/rehacer"
	comandos_columna.add_child(comandos_5)
	var comandos_6 := Label.new()
	comandos_6.text = "B: colocacion  |  F5: vista limpia  |  Rueda: zoom por zona"
	comandos_6.clip_text = true
	comandos_6.add_theme_font_size_override("font_size", 11)
	comandos_6.text = "B colocacion    ·    F5 vista limpia"
	comandos_columna.add_child(comandos_6)
	var comandos_7 := Label.new()
	comandos_7.text = "N ajuste · Ctrl+C/V copiar/pegar · Ctrl+D duplicar"
	comandos_7.clip_text = true
	comandos_7.add_theme_font_size_override("font_size", 11)
	comandos_columna.add_child(comandos_7)
	var comandos_8 := Label.new()
	comandos_8.text = "Ctrl+Shift+H/V alinear · VALIDAR y bloqueos en panel"
	comandos_8.clip_text = true
	comandos_8.add_theme_font_size_override("font_size", 11)
	comandos_columna.add_child(comandos_8)
	comandos_1.text = "LMB: seleccionar/mover  |  RMB: cancelar"
	comandos_2.text = "Flechas: 1 px  |  Shift: 8 px  |  Ctrl: 1 tile"
	comandos_3.text = "R: espejo horizontal  |  F: espejo vertical  |  U: restaurar  |  [ ]: asset"
	comandos_4.text = "G: rejilla  |  W: rejilla muros  |  V: subrejilla 2x2  |  T: transitabilidad  |  C: colisiones  |  L: capas"
	comandos_5.text = "Ctrl+S: guardar  |  Ctrl+O: cargar  |  Ctrl+Z/Y: deshacer"
	comandos_6.text = "B: colocacion  |  F5: vista limpia  |  Rueda: zoom por zona"
	_actualizar_modo_editor()
	_actualizar_estado("Editor listo. Selecciona un muro o mueble")
	_crear_paleta(capa)
	_actualizar_flechas_paneles()
	_actualizar_botones_herramientas()
	_actualizar_botones_capas()
	_actualizar_visibilidad_capas()

func _crear_boton_capa(contenedor: Container, texto: String, capa: String) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(78, 23)
	boton.add_theme_font_size_override("font_size", 8)
	boton.tooltip_text = "Mostrar u ocultar la capa %s sin borrar sus elementos" % capa
	boton.pressed.connect(_alternar_visibilidad_capa.bind(capa))
	contenedor.add_child(boton)
	return boton

func _crear_controles_calibracion(columna: VBoxContainer) -> void:
	var titulo := Label.new()
	titulo.text = "CALIBRACION VISUAL · I guia · K restaurar"
	titulo.add_theme_font_size_override("font_size", 10)
	titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	columna.add_child(titulo)
	var fila_offset := HBoxContainer.new()
	var texto_offset := Label.new()
	texto_offset.text = "Calib X/Y"
	texto_offset.custom_minimum_size = Vector2(58, 0)
	fila_offset.add_child(texto_offset)
	_cal_offset_x = _crear_spin_calibracion(fila_offset, -512.0, 512.0, 1.0)
	_cal_offset_y = _crear_spin_calibracion(fila_offset, -512.0, 512.0, 1.0)
	columna.add_child(fila_offset)
	var fila_escala := HBoxContainer.new()
	var texto_escala := Label.new()
	texto_escala.text = "Escala X/Y"
	texto_escala.custom_minimum_size = Vector2(58, 0)
	fila_escala.add_child(texto_escala)
	_cal_escala_x = _crear_spin_calibracion(fila_escala, -4.0, 4.0, 0.01)
	_cal_escala_y = _crear_spin_calibracion(fila_escala, -4.0, 4.0, 0.01)
	columna.add_child(fila_escala)
	var fila_deformacion := HBoxContainer.new()
	var texto_deformacion := Label.new()
	texto_deformacion.text = "Sesgo/Rot"
	texto_deformacion.custom_minimum_size = Vector2(58, 0)
	fila_deformacion.add_child(texto_deformacion)
	_cal_skew = _crear_spin_calibracion(fila_deformacion, -45.0, 45.0, 0.1)
	_cal_rotacion = _crear_spin_calibracion(fila_deformacion, -180.0, 180.0, 1.0)
	columna.add_child(fila_deformacion)
	var gizmo_titulo := Label.new()
	gizmo_titulo.text = "GIZMO 2D · rotacion y espejo"
	gizmo_titulo.add_theme_font_size_override("font_size", 10)
	gizmo_titulo.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	columna.add_child(gizmo_titulo)
	var fila_gizmo := HBoxContainer.new()
	fila_gizmo.add_theme_constant_override("separation", 3)
	_crear_boton_gizmo(fila_gizmo, "↺ 90", _gizmo_girar.bind(-90.0))
	_crear_boton_gizmo(fila_gizmo, "↻ 90", _gizmo_girar.bind(90.0))
	_crear_boton_gizmo(fila_gizmo, "↔", _gizmo_espejar_horizontal)
	_crear_boton_gizmo(fila_gizmo, "↕", _gizmo_espejar_vertical)
	_crear_boton_gizmo(fila_gizmo, "0°", _gizmo_restaurar_orientacion)
	columna.add_child(fila_gizmo)

func _crear_spin_calibracion(contenedor: Container, minimo: float, maximo: float, paso: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimo
	spin.max_value = maximo
	spin.step = paso
	spin.custom_minimum_size = Vector2(78, 22)
	spin.add_theme_font_size_override("font_size", 9)
	spin.value_changed.connect(_cambiar_calibracion)
	_hacer_spin_editable(spin)
	contenedor.add_child(spin)
	return spin

func _hacer_spin_editable(spin: SpinBox) -> void:
	## Mantiene las flechas, pero permite escribir el valor directamente.
	## Enter confirma; el valor se limita al rango del control.
	var campo: LineEdit = spin.get_line_edit()
	if campo == null:
		return
	campo.editable = true
	campo.select_all_on_focus = true
	campo.text_submitted.connect(_confirmar_valor_spin.bind(spin))
	campo.focus_entered.connect(campo.select_all)

func _confirmar_valor_spin(texto: String, spin: SpinBox) -> void:
	var limpio := texto.strip_edges().replace(",", ".")
	if limpio.is_valid_float():
		spin.value = clampf(float(limpio), spin.min_value, spin.max_value)
	else:
		spin.get_line_edit().text = str(spin.value)
	spin.get_line_edit().release_focus()

func _crear_boton_gizmo(contenedor: Container, texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(42, 22)
	boton.add_theme_font_size_override("font_size", 10)
	boton.tooltip_text = "Transformacion visual del sprite seleccionado"
	boton.pressed.connect(accion)
	contenedor.add_child(boton)

func _ajustes_visual_seleccionado() -> Dictionary:
	if _seleccionado == null or not is_instance_valid(_seleccionado):
		return {}
	return _seleccionado.get_meta("layout_calibracion", {})

func _gizmo_girar(grados: float) -> void:
	if _seleccionado == null or not is_instance_valid(_seleccionado):
		return
	var ajustes := _ajustes_visual_seleccionado().duplicate(true)
	var rotacion := fposmod(float(ajustes.get("rotacion", 0.0)) + grados + 180.0, 360.0) - 180.0
	ajustes["rotacion"] = rotacion
	_guardar_historial()
	_aplicar_calibracion_a_nodo(_seleccionado, ajustes)
	_actualizar_calibrador_desde_seleccion()
	_actualizar_estado("Gizmo: rotacion visual %d grados" % roundi(rotacion))
	queue_redraw()

func _gizmo_espejar_horizontal() -> void:
	_gizmo_espejar(Vector2(-1.0, 1.0), "horizontal")

func _gizmo_espejar_vertical() -> void:
	_gizmo_espejar(Vector2(1.0, -1.0), "vertical")

func _gizmo_espejar(factor: Vector2, nombre: String) -> void:
	if _seleccionado == null or not is_instance_valid(_seleccionado):
		return
	var ajustes := _ajustes_visual_seleccionado().duplicate(true)
	var escala: Array = ajustes.get("escala", [1.0, 1.0])
	var actual := Vector2(float(escala[0]), float(escala[1])) if escala.size() >= 2 else Vector2.ONE
	ajustes["escala"] = [actual.x * factor.x, actual.y * factor.y]
	_guardar_historial()
	_aplicar_calibracion_a_nodo(_seleccionado, ajustes)
	_actualizar_calibrador_desde_seleccion()
	_actualizar_estado("Gizmo: espejo %s" % nombre)
	queue_redraw()

func _gizmo_restaurar_orientacion() -> void:
	if _seleccionado == null or not is_instance_valid(_seleccionado):
		return
	var ajustes := _ajustes_visual_seleccionado().duplicate(true)
	ajustes["rotacion"] = 0.0
	var escala: Array = ajustes.get("escala", [1.0, 1.0])
	if escala.size() >= 2:
		ajustes["escala"] = [absf(float(escala[0])), absf(float(escala[1]))]
	_guardar_historial()
	_aplicar_calibracion_a_nodo(_seleccionado, ajustes)
	_actualizar_calibrador_desde_seleccion()
	_actualizar_estado("Gizmo: orientacion restaurada")
	queue_redraw()

func _crear_boton_tamano(contenedor: Container, texto: String, delta_ancho: int, delta_alto: int) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(52, 22)
	boton.add_theme_font_size_override("font_size", 9)
	boton.tooltip_text = "Reducir o ampliar casillas de la sala (solo editor)"
	boton.pressed.connect(_cambiar_tamano_editor.bind(delta_ancho, delta_alto))
	contenedor.add_child(boton)

func _cambiar_tamano_editor(delta_ancho: int, delta_alto: int) -> void:
	if interior == null or interior.definicion == null:
		return
	var nuevo_ancho := maxi(TAMANO_MINIMO, _ancho_editor + delta_ancho)
	var nuevo_alto := maxi(TAMANO_MINIMO, _alto_editor + delta_alto)
	if nuevo_ancho == _ancho_editor and nuevo_alto == _alto_editor:
		return
	# No permitimos cortar un mueble o una transición: así el editor nunca
	# deja una puerta, una estación o un cofre fuera de la sala sin avisar.
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo) or not nodo.visible:
			continue
		if str(nodo.get_meta("layout_role", "")) not in ["mueble", "transicion"]:
			continue
		var origen: Vector2i = nodo.get_meta("layout_casilla", Vector2i.ZERO)
		var huella: Vector2i = nodo.get_meta("layout_huella", Vector2i.ONE)
		if origen.x < 0 or origen.y < 0 or origen.x + huella.x > nuevo_ancho or origen.y + huella.y > nuevo_alto:
			_actualizar_estado("Tamaño rechazado: %s quedaría fuera de la sala" % str(nodo.get_meta("layout_id", "mueble")))
			return
	_guardar_respaldo_automatico("cambio de tamano")
	_guardar_historial()
	_ancho_editor = nuevo_ancho
	_alto_editor = nuevo_alto
	_aplicar_tamano_visual()
	_actualizar_estado("Sala ajustada a %d x %d casillas. Ctrl+S para guardar." % [_ancho_editor, _alto_editor])
	queue_redraw()

func _aplicar_tamano_visual() -> void:
	if interior == null:
		return
	# El editor posee su propia rejilla: la definición compartida de la partida
	# nunca se modifica. Esto permite experimentar sin cambiar mundo.tscn.
	var rejilla := TransitableRejilla.new(_ancho_editor, _alto_editor)
	rejilla.amurallar()
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo):
			continue
		var rol := str(nodo.get_meta("layout_role", ""))
		var casilla: Vector2i = nodo.get_meta("layout_casilla", Vector2i(-999, -999))
		var huella: Vector2i = nodo.get_meta("layout_huella", Vector2i.ONE)
		if rol == "suelo" or rol == "muro" or rol == "borde":
			var dentro := casilla.x >= 0 and casilla.y >= 0 and casilla.x < _ancho_editor and casilla.y < _alto_editor
			if dentro:
				nodo.set_meta("layout_oculto_por_tamano", false)
				nodo.visible = not _base_oculta_por_boton
			else:
				nodo.set_meta("layout_oculto_por_tamano", true)
				nodo.visible = false
		elif rol == "transicion":
			var dentro_transicion := casilla.x >= 0 and casilla.y >= 0 and casilla.x < _ancho_editor and casilla.y < _alto_editor
			nodo.visible = dentro_transicion and not bool(nodo.get_meta("layout_oculto_por_boton", false))
		elif rol == "mueble" and nodo.visible and bool(nodo.get_meta("layout_solido", true)):
			for dy in huella.y:
				for dx in huella.x:
					var celda := casilla + Vector2i(dx, dy)
					if celda.x >= 0 and celda.y >= 0 and celda.x < _ancho_editor and celda.y < _alto_editor:
						rejilla.bloquear(celda, "mueble")
	var entrada := Vector2i(clampi(interior.definicion.entrada.x, 1, maxi(1, _ancho_editor - 2)), clampi(interior.definicion.entrada.y, 1, maxi(1, _alto_editor - 2)))
	rejilla.liberar(entrada)
	interior.transitable = rejilla
	_crear_base_faltante()
	_actualizar_visibilidad_capas()
	_actualizar_respaldo_editor()
	_actualizar_panel()

func _crear_base_faltante() -> void:
	if interior == null or interior.definicion == null:
		return
	var clave_suelo := interior.definicion.asset_suelo
	var clave_norte := interior.definicion.asset_muro_norte
	var clave_oeste := interior.definicion.asset_muro_oeste
	if clave_suelo == "" or clave_norte == "" or clave_oeste == "":
		return
	for y in _alto_editor:
		for x in _ancho_editor:
			if _buscar_base_en_casilla(Vector2i(x, y), "suelo") == null:
				_crear_base_editor(Vector2i(x, y), "suelo", clave_suelo)
	for x in _ancho_editor:
		if _buscar_base_en_casilla(Vector2i(x, 0), "muro") == null:
			_crear_base_editor(Vector2i(x, 0), "muro", _asset_muro_para_casilla(Vector2i(x, 0)))
	for y in range(1, _alto_editor):
		if _buscar_base_en_casilla(Vector2i(0, y), "muro") == null:
			_crear_base_editor(Vector2i(0, y), "muro", _asset_muro_para_casilla(Vector2i(0, y)))

func _buscar_base_en_casilla(casilla: Vector2i, rol: String) -> Node2D:
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo != null and is_instance_valid(nodo) and str(nodo.get_meta("layout_role", "")) == rol and nodo.get_meta("layout_casilla", Vector2i(-999, -999)) == casilla:
			return nodo
	return null

## La rejilla de muros usa aristas del rombo, no centros de baldosa.
##
## Un segmento X avanza por la arista (64,32) y un segmento Y por la arista
## (-64,32). Ambos comienzan en el vértice superior de su baldosa lógica.
## La casilla se conserva como coordenada de datos para no romper layouts
## existentes; layout_wall_axis identifica ahora la arista física.
func _eje_muro(clave: String, casilla: Vector2i = Vector2i.ZERO) -> String:
	if clave.contains("muro_esquina") or clave.contains("muro_borde") or clave.contains("pilar"):
		return "esquina"
	if clave.contains("muro_oeste"):
		return "x"
	if clave.contains("muro_norte"):
		return "y"
	if casilla.y == 0:
		return "x"
	return "y"

func _posicion_muro_local(casilla: Vector2i, clave: String = "") -> Vector2:
	return Iso.centro_v(casilla) + Vector2(0.0, -Iso.MEDIO_Y)

func _posicion_muro_global(casilla: Vector2i, clave: String = "") -> Vector2:
	if interior == null or not is_instance_valid(interior):
		return Iso.centro_v(casilla)
	return interior.to_global(_posicion_muro_local(casilla, clave))

func _direccion_arista_muro(eje: String) -> Vector2:
	return Vector2(Iso.MEDIO_X, Iso.MEDIO_Y) if eje == "x" else Vector2(-Iso.MEDIO_X, Iso.MEDIO_Y)

func _crear_base_editor(casilla: Vector2i, rol: String, clave: String) -> Node2D:
	var nodo := Node2D.new()
	var id := "base_editor_%s_%02d_%02d" % [rol, casilla.x, casilla.y]
	nodo.name = id
	nodo.position = _posicion_muro_local(casilla, clave) if rol in ["muro", "borde"] else Iso.centro(casilla.x, casilla.y)
	nodo.set_meta("layout_id", id)
	nodo.set_meta("layout_role", rol)
	nodo.set_meta("layout_asset", clave)
	nodo.set_meta("layout_casilla", casilla)
	nodo.set_meta("layout_huella", Vector2i.ONE)
	nodo.set_meta("layout_solido", rol == "muro")
	nodo.set_meta("layout_base_position", nodo.position)
	if rol in ["muro", "borde"]:
		nodo.set_meta("layout_wall_axis", _eje_muro(clave, casilla))
	if rol == "suelo":
		var sprite := _crear_sprite_suelo(clave, casilla)
		nodo.add_child(sprite)
	else:
		nodo.add_child(_crear_sprite_asset(clave))
	var contenedor := interior.get_node_or_null("ArteBase") as Node2D
	if contenedor == null:
		contenedor = interior
	contenedor.add_child(nodo)
	if rol == "suelo":
		contenedor.move_child(nodo, 0)
	_elementos[id] = nodo
	_orden_ids.append(id)
	_orden_ids.sort()
	return nodo

func _crear_sprite_suelo(clave: String, casilla: Vector2i) -> Sprite2D:
	var sprite := Sprite2D.new()
	var textura := Assets.textura(clave)
	var datos := Assets.datos(clave)
	var celda: Array = datos.get("celda_fisica", [128, 64])
	var atlas := AtlasTexture.new()
	var num_celdas := maxi(1, int(textura.get_width() / float(celda[0]))) if textura != null else 1
	var indice := _indice_suelo_editor(casilla.x, casilla.y, 1)
	atlas.atlas = Assets.textura_celda(clave, indice, Vector2i(int(celda[0]), int(celda[1])))
	atlas.region = Rect2(0.0, 0.0, float(celda[0]), float(celda[1]))
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite

func _indice_suelo_editor(x: int, y: int, total: int) -> int:
	return 0

func _actualizar_respaldo_editor() -> void:
	var arte := interior.get_node_or_null("ArteBase")
	if arte == null or not arte.has_method("configurar_respaldo"):
		return
	var poligono := PackedVector2Array([
		Iso.centro(0, 0) + Vector2(0, -Iso.MEDIO_Y),
		Iso.centro(_ancho_editor - 1, 0) + Vector2(Iso.MEDIO_X, 0),
		Iso.centro(_ancho_editor - 1, _alto_editor - 1) + Vector2(0, Iso.MEDIO_Y),
		Iso.centro(0, _alto_editor - 1) + Vector2(-Iso.MEDIO_X, 0),
	])
	arte.configurar_respaldo(poligono, arte.respaldo_color)

func _crear_boton_flecha(posicion: Vector2) -> Button:
	var boton := Button.new()
	boton.position = posicion
	boton.custom_minimum_size = Vector2(28, 28)
	boton.size = Vector2(28, 28)
	boton.add_theme_font_size_override("font_size", 14)
	boton.tooltip_text = "Plegar o mostrar este panel"
	return boton

func _crear_boton_mover(ayuda: String) -> Button:
	var boton := Button.new()
	boton.text = "✥"
	boton.custom_minimum_size = Vector2(28, 28)
	boton.size = Vector2(28, 28)
	boton.add_theme_font_size_override("font_size", 14)
	boton.tooltip_text = ayuda
	return boton

func _actualizar_flechas_paneles() -> void:
	if _boton_panel != null:
		if _panel != null:
			_boton_panel.position = _panel.position + Vector2(maxf(0.0, _panel.size.x - 30.0), 2.0)
		_boton_panel.text = "<" if _panel_expandido else ">"
		_boton_panel.tooltip_text = "Ocultar editor" if _panel_expandido else "Mostrar editor"
	if _boton_comandos != null:
		if _panel_comandos != null:
			_boton_comandos.position = _panel_comandos.position + Vector2(maxf(0.0, _panel_comandos.size.x - 30.0), 2.0)
		_boton_comandos.text = "<" if _comandos_expandidos else ">"
		_boton_comandos.tooltip_text = "Ocultar comandos" if _comandos_expandidos else "Mostrar comandos"
	_actualizar_manejadores_ui()

func _actualizar_manejadores_ui() -> void:
	var visible_ui := not _vista_limpia
	if _boton_mover_panel != null and is_instance_valid(_boton_mover_panel):
		_boton_mover_panel.position = _panel.position + Vector2(4.0, 2.0) if _panel != null else Vector2.ZERO
		_boton_mover_panel.visible = visible_ui and _panel_expandido
	if _boton_mover_comandos != null and is_instance_valid(_boton_mover_comandos):
		_boton_mover_comandos.position = _panel_comandos.position + Vector2(4.0, 2.0) if _panel_comandos != null else Vector2.ZERO
		_boton_mover_comandos.visible = visible_ui and _comandos_expandidos
	if _boton_mover_referencia != null and is_instance_valid(_boton_mover_referencia):
		if referencia != null and is_instance_valid(referencia) and referencia.texture != null:
			var tamano := Vector2(referencia.texture.get_size()) * referencia.scale.abs()
			_boton_mover_referencia.position = referencia.position - tamano * 0.5 + Vector2(4.0, 4.0)
			_boton_mover_referencia.visible = visible_ui and _referencia_visible
		else:
			_boton_mover_referencia.visible = false

func _gestionar_arrastre_ui(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var objetivo := ""
			if _boton_mover_panel != null and _boton_mover_panel.visible and _boton_mover_panel.get_global_rect().has_point(event.position):
				objetivo = "editor"
			elif _boton_mover_comandos != null and _boton_mover_comandos.visible and _boton_mover_comandos.get_global_rect().has_point(event.position):
				objetivo = "comandos"
			elif _boton_mover_referencia != null and _boton_mover_referencia.visible and _boton_mover_referencia.get_global_rect().has_point(event.position):
				objetivo = "referencia"
			if objetivo != "":
				_ui_arrastrando = objetivo
				_ui_arrastre_inicio = event.position
				match objetivo:
					"editor": _ui_pos_inicio = _panel.position
					"comandos": _ui_pos_inicio = _panel_comandos.position
					"referencia": _ui_pos_inicio = referencia.position
				get_viewport().set_input_as_handled()
				return true
		elif _ui_arrastrando != "":
			_ui_arrastrando = ""
			get_viewport().set_input_as_handled()
			return true
	if event is InputEventMouseMotion and _ui_arrastrando != "":
		var nueva_pos: Vector2 = _ui_pos_inicio + (event.position - _ui_arrastre_inicio)
		match _ui_arrastrando:
			"editor":
				_panel.position = _limitar_posicion_panel(_panel, nueva_pos)
			"comandos":
				_panel_comandos.position = _limitar_posicion_panel(_panel_comandos, nueva_pos)
			"referencia":
				referencia.position = _limitar_posicion_referencia(nueva_pos)
		_actualizar_flechas_paneles()
		get_viewport().set_input_as_handled()
		return true
	return false

func _limitar_posicion_panel(panel: Control, posicion: Vector2) -> Vector2:
	if panel == null:
		return posicion
	var viewport_size := get_viewport_rect().size
	var tamano := panel.size
	if tamano.x <= 1.0 or tamano.y <= 1.0:
		tamano = panel.get_combined_minimum_size()
	var margen := 8.0
	return Vector2(
		clampf(posicion.x, margen, maxf(margen, viewport_size.x - tamano.x - margen)),
		clampf(posicion.y, margen, maxf(margen, viewport_size.y - tamano.y - margen))
	)

func _limitar_posicion_referencia(posicion: Vector2) -> Vector2:
	if referencia == null or not is_instance_valid(referencia) or referencia.texture == null:
		return posicion
	var viewport_size := get_viewport_rect().size
	var mitad := Vector2(referencia.texture.get_size()) * referencia.scale.abs() * 0.5
	var margen := 8.0
	return Vector2(
		clampf(posicion.x, mitad.x + margen, maxf(mitad.x + margen, viewport_size.x - mitad.x - margen)),
		clampf(posicion.y, mitad.y + margen, maxf(mitad.y + margen, viewport_size.y - mitad.y - margen))
	)

func _alternar_panel_editor() -> void:
	_panel_expandido = not _panel_expandido
	if _panel != null:
		_panel.visible = _panel_expandido
	_actualizar_flechas_paneles()
	_actualizar_estado("Panel del editor %s" % ("abierto" if _panel_expandido else "plegado"))

func _alternar_panel_comandos() -> void:
	_comandos_expandidos = not _comandos_expandidos
	if _panel_comandos != null:
		_panel_comandos.visible = _comandos_expandidos
	_actualizar_flechas_paneles()
	_actualizar_estado("Panel de comandos %s" % ("abierto" if _comandos_expandidos else "plegado"))

func _crear_paleta(capa: CanvasLayer) -> void:
	_paleta = PanelContainer.new()
	_paleta.position = Vector2(70, 560)
	_paleta.custom_minimum_size = Vector2(620, 92)
	_paleta.add_theme_stylebox_override("panel", _estilo_panel(Color("#172238"), Color("#5cb2b5"), 2, 0.96))
	capa.add_child(_paleta)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 3)
	_paleta.add_child(columna)
	_paleta_categoria = Label.new()
	_paleta_categoria.add_theme_font_size_override("font_size", 13)
	_paleta_categoria.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	columna.add_child(_paleta_categoria)
	_boton_relleno_muro_paleta = Button.new()
	_boton_relleno_muro_paleta.text = "RELLENAR MURO [M]: OFF"
	_boton_relleno_muro_paleta.custom_minimum_size = Vector2(0, 24)
	_boton_relleno_muro_paleta.add_theme_font_size_override("font_size", 10)
	_boton_relleno_muro_paleta.tooltip_text = "Traza un rectangulo de muros rectos con RMB"
	_boton_relleno_muro_paleta.pressed.connect(_alternar_modo_relleno_muro)
	columna.add_child(_boton_relleno_muro_paleta)
	_paleta_busqueda = LineEdit.new()
	_paleta_busqueda.placeholder_text = "Buscar asset..."
	_paleta_busqueda.custom_minimum_size = Vector2(0, 24)
	_paleta_busqueda.add_theme_font_size_override("font_size", 10)
	_paleta_busqueda.text_changed.connect(_filtrar_paleta)
	columna.add_child(_paleta_busqueda)
	var tabs := HBoxContainer.new()
	columna.add_child(tabs)
	for i in CATEGORIAS.size():
		var boton := Button.new()
		boton.text = "%d  %s" % [i + 1, CATEGORIAS[i]]
		boton.custom_minimum_size = Vector2(140, 24)
		boton.add_theme_font_size_override("font_size", 10)
		boton.disabled = (_modo_editor == ModoEditor.BASE and i > 1) or (_modo_editor == ModoEditor.OBJETOS and i < 2)
		boton.pressed.connect(_seleccionar_categoria.bind(i))
		tabs.add_child(boton)
		_botones_categorias.append(boton)
	var navegacion := HBoxContainer.new()
	navegacion.add_theme_constant_override("separation", 4)
	columna.add_child(navegacion)
	_boton_paleta_anterior = Button.new()
	_boton_paleta_anterior.text = "‹"
	_boton_paleta_anterior.custom_minimum_size = Vector2(30, 22)
	_boton_paleta_anterior.tooltip_text = "Assets anteriores"
	_boton_paleta_anterior.pressed.connect(_cambiar_pagina_paleta.bind(-1))
	navegacion.add_child(_boton_paleta_anterior)
	_paleta_pagina = Label.new()
	_paleta_pagina.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_paleta_pagina.custom_minimum_size = Vector2(100, 22)
	_paleta_pagina.add_theme_font_size_override("font_size", 10)
	navegacion.add_child(_paleta_pagina)
	_boton_paleta_siguiente = Button.new()
	_boton_paleta_siguiente.text = "›"
	_boton_paleta_siguiente.custom_minimum_size = Vector2(30, 22)
	_boton_paleta_siguiente.tooltip_text = "Assets siguientes"
	_boton_paleta_siguiente.pressed.connect(_cambiar_pagina_paleta.bind(1))
	navegacion.add_child(_boton_paleta_siguiente)
	_paleta_slots = HBoxContainer.new()
	_paleta_slots.add_theme_constant_override("separation", 5)
	columna.add_child(_paleta_slots)
	_actualizar_paleta()
	_boton_paleta = _crear_boton_flecha(Vector2.ZERO)
	_boton_paleta.pressed.connect(_alternar_paleta)
	capa.add_child(_boton_paleta)
	_boton_mover_paleta = Button.new()
	_boton_mover_paleta.text = "✥"
	_boton_mover_paleta.custom_minimum_size = Vector2(28, 28)
	_boton_mover_paleta.size = Vector2(28, 28)
	_boton_mover_paleta.add_theme_font_size_override("font_size", 14)
	_boton_mover_paleta.tooltip_text = "Arrastrar paleta de assets"
	capa.add_child(_boton_mover_paleta)
	_actualizar_flechas_paleta()
	_ajustar_paleta_al_viewport()

func _ajustar_paleta_al_viewport() -> void:
	if _paleta == null or not is_instance_valid(_paleta):
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var tamano := _paleta.size
	if tamano.x <= 1.0 or tamano.y <= 1.0:
		tamano = _paleta.get_combined_minimum_size()
	var margen := 12.0
	var x_max := maxf(margen, viewport_size.x - tamano.x - margen)
	var y_max := maxf(margen, viewport_size.y - tamano.y - margen)
	var y_inicial := y_max if not _paleta_posicionada_manualmente else _paleta.position.y
	var posicion := Vector2(clampf(_paleta.position.x, margen, x_max), clampf(y_inicial, margen, y_max))
	if _tamano_viewport_editor != viewport_size or _paleta.position != posicion:
		_tamano_viewport_editor = viewport_size
		_paleta.position = posicion
	_actualizar_flechas_paleta()

func _actualizar_flechas_paleta() -> void:
	if _paleta == null or not is_instance_valid(_paleta):
		return
	var tamano := _paleta.size
	if tamano.x <= 1.0 or tamano.y <= 1.0:
		tamano = _paleta.get_combined_minimum_size()
	if _boton_paleta != null and is_instance_valid(_boton_paleta):
		_boton_paleta.position = _paleta.position + Vector2(maxf(0.0, tamano.x - 30.0), 2.0)
		_boton_paleta.text = "<" if _paleta_expandida else ">"
		_boton_paleta.tooltip_text = "Ocultar paleta" if _paleta_expandida else "Mostrar paleta"
		_boton_paleta.visible = true
	if _boton_mover_paleta != null and is_instance_valid(_boton_mover_paleta):
		_boton_mover_paleta.position = _paleta.position + Vector2(4.0, 2.0)
		_boton_mover_paleta.visible = _paleta_expandida

func _alternar_paleta() -> void:
	_paleta_expandida = not _paleta_expandida
	if _paleta != null:
		_paleta.visible = _paleta_expandida
	_actualizar_flechas_paleta()
	_actualizar_estado("Paleta de assets %s" % ("abierta" if _paleta_expandida else "plegada"))

func _gestionar_arrastre_paleta(event: InputEvent) -> bool:
	if _boton_mover_paleta == null or not is_instance_valid(_boton_mover_paleta):
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _boton_mover_paleta.visible and _boton_mover_paleta.get_global_rect().has_point(event.position):
			_panel_arrastrado = _paleta
			_panel_arrastre_inicio = event.position
			_panel_pos_inicio = _paleta.position
			get_viewport().set_input_as_handled()
			return true
		if not event.pressed and _panel_arrastrado == _paleta:
			_panel_arrastrado = null
			get_viewport().set_input_as_handled()
			return true
	if event is InputEventMouseMotion and _panel_arrastrado == _paleta:
		_paleta_posicionada_manualmente = true
		_paleta.position = _panel_pos_inicio + (event.position - _panel_arrastre_inicio)
		_ajustar_paleta_al_viewport()
		get_viewport().set_input_as_handled()
		return true
	return false

func _seleccionar_categoria(indice: int) -> void:
	if _modo_editor == ModoEditor.BASE and indice > 1:
		_actualizar_estado("Primero valida la base para editar objetos")
		return
	if _modo_editor == ModoEditor.OBJETOS and indice < 2:
		_actualizar_estado("La base está protegida en modo objetos")
		return
	_categoria_actual = clampi(indice, 0, CATEGORIAS.size() - 1)
	_pagina_paleta = 0
	_actualizar_paleta()

func _filtrar_paleta(_texto: String) -> void:
	_pagina_paleta = 0
	_actualizar_paleta()

func _cambiar_pagina_paleta(delta: int) -> void:
	var paginas := _total_paginas_paleta()
	_pagina_paleta = clampi(_pagina_paleta + delta, 0, maxi(0, paginas - 1))
	_actualizar_paleta()
	_actualizar_estado("Página de assets %d/%d" % [_pagina_paleta + 1, paginas])

func _total_paginas_paleta() -> int:
	var cantidad := _assets_de_categoria(_categoria_actual).size()
	return maxi(1, int(ceil(float(cantidad) / float(SLOTS_POR_PAGINA))))

func _actualizar_paleta() -> void:
	if _paleta_categoria == null or _paleta_slots == null:
		return
	_paleta_categoria.text = "PALETA DE ASSETS · Slot %d: %s · clic y arrastra el asset a la sala" % [_categoria_actual + 1, CATEGORIAS[_categoria_actual]]
	for hijo in _paleta_slots.get_children():
		hijo.queue_free()
	_slot_claves.clear()
	var claves := _assets_de_categoria(_categoria_actual)
	var total_paginas := maxi(1, int(ceil(float(claves.size()) / float(SLOTS_POR_PAGINA))))
	_pagina_paleta = clampi(_pagina_paleta, 0, total_paginas - 1)
	var inicio := _pagina_paleta * SLOTS_POR_PAGINA
	var fin := mini(inicio + SLOTS_POR_PAGINA, claves.size())
	for i in range(inicio, fin):
		var clave := claves[i]
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(86, 42)
		boton.text = _nombre_corto(clave)
		boton.tooltip_text = clave
		boton.icon = _icono_asset(clave)
		boton.add_theme_font_size_override("font_size", 9)
		boton.pressed.connect(_seleccionar_asset_paleta.bind(clave))
		_paleta_slots.add_child(boton)
		_slot_claves.append(clave)
	if _paleta_pagina != null:
		_paleta_pagina.text = "Página %d/%d · %d assets" % [_pagina_paleta + 1, total_paginas, claves.size()]
	if _boton_paleta_anterior != null:
		_boton_paleta_anterior.disabled = _pagina_paleta <= 0
	if _boton_paleta_siguiente != null:
		_boton_paleta_siguiente.disabled = _pagina_paleta >= total_paginas - 1

func _assets_de_categoria(indice: int) -> Array[String]:
	var salida: Array[String] = []
	for cruda in Assets.claves():
		var clave := str(cruda)
		var datos := Assets.datos(clave)
		var tipo := str(datos.get("tipo", ""))
		if indice == 0 and tipo == "sprite" and clave.contains("muro"):
			salida.append(clave)
		elif indice == 1 and tipo == "atlas_tile" and clave.contains("suelo"):
			salida.append(clave)
		elif indice == 2 and tipo == "sprite" and (clave.contains("mueble") or clave.contains("objeto")):
			salida.append(clave)
		elif indice == 3 and tipo == "sprite" and (clave.contains("escalera") or clave.contains("puerta")):
			salida.append(clave)
		salida.sort()
	var filtro := _paleta_busqueda.text.strip_edges().to_lower() if _paleta_busqueda != null else ""
	if not filtro.is_empty():
		salida = salida.filter(func(clave: String) -> bool:
			return clave.to_lower().contains(filtro) or _nombre_corto(clave).to_lower().contains(filtro)
		)
	return salida

func _nombre_corto(clave: String) -> String:
	if clave.contains("muro_norte"):
		return "Muro recto X"
	if clave.contains("muro_oeste"):
		return "Muro recto Y"
	if clave.contains("muro_esquina"):
		return "Esquina de muro"
	if clave.contains("muro_borde") or clave.contains("pilar"):
		return "Pilar / borde"
	var partes := clave.split(".")
	return partes[-1].replace("_", " ").left(12)

func _icono_asset(clave: String) -> Texture2D:
	var textura := Assets.textura(clave)
	if textura == null:
		return null
	var imagen := textura.get_image()
	if imagen == null or imagen.is_empty():
		return null
	var datos := Assets.datos(clave)
	if str(datos.get("tipo", "")) == "atlas_tile":
		var celda: Array = datos.get("celda_fisica", [128, 64])
		if celda.size() >= 2:
			var ancho := mini(int(celda[0]), imagen.get_width())
			var alto := mini(int(celda[1]), imagen.get_height())
			imagen = imagen.get_region(Rect2i(0, 0, ancho, alto))
	imagen.resize(28, 28, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(imagen)

func _seleccionar_asset_paleta(clave: String) -> void:
	if not _asset_permitido_en_modo(clave):
		_actualizar_estado("Cambia al modo correcto para usar este asset")
		return
	var datos := Assets.datos(clave)
	var es_base := str(datos.get("tipo", "")) == "atlas_tile" or clave.contains("muro")
	var capa := "base" if es_base else "objetos"
	if bool(_capas_bloqueadas.get(capa, false)):
		_actualizar_estado("La capa %s está bloqueada" % capa)
		return
	_asset_activo = clave
	_colocando_asset = true
	_crear_preview_asset()
	_actualizar_estado("Asset preparado: %s · mueve el cursor y haz clic para colocar" % clave)

func _crear_preview_asset() -> void:
	if _asset_preview != null and is_instance_valid(_asset_preview):
		_asset_preview.queue_free()
	_asset_preview = null
	if _asset_activo == "" or interior == null or not Assets.existe(_asset_activo):
		return
	var sprite := _crear_sprite_asset(_asset_activo)
	sprite.modulate = Color(0.35, 1.0, 0.45, 0.65)
	_asset_preview = Node2D.new()
	_asset_preview.name = "PreviewAsset"
	_asset_preview.add_child(sprite)
	interior.add_child(_asset_preview)

func _actualizar_preview_asset() -> void:
	if not _colocando_asset or _asset_preview == null or interior == null:
		return
	if _modo_relleno_muro:
		_asset_preview.visible = false
		return
	if _asset_activo.contains("muro"):
		var info := _muro_celda_bajo_cursor(get_global_mouse_position())
		if info.is_empty():
			_asset_preview.visible = false
			return
		_asset_preview.visible = true
		var casilla: Vector2i = info.casilla
		var eje: String = info.eje
		_asset_preview.position = interior.to_local(_posicion_muro_global(casilla, _clave_muro_para_eje(eje)))
		return
	if not _cursor_en_sala():
		_asset_preview.visible = false
		return
	_asset_preview.visible = true
	var local := interior.to_local(get_global_mouse_position())
	_asset_preview.position = Iso.centro_v(Iso.a_tile(local))

func _cursor_en_sala() -> bool:
	if interior == null:
		return false
	var local := interior.to_local(get_global_mouse_position())
	var tile := Iso.a_tile(local)
	return tile.x >= 0 and tile.y >= 0 and tile.x < _ancho_editor and tile.y < _alto_editor

func _colocar_asset_activo() -> void:
	if not _colocando_asset or _asset_activo == "" or interior == null or not _cursor_en_sala():
		return
	var local := interior.to_local(get_global_mouse_position())
	var tile := Iso.a_tile(local)
	_guardar_historial()
	_colocar_asset_en_tile(tile, _asset_activo)

func _asset_permitido_en_modo(clave: String) -> bool:
	var datos := Assets.datos(clave)
	var tipo := str(datos.get("tipo", ""))
	var es_suelo := tipo == "atlas_tile"
	if _modo_editor == ModoEditor.BASE:
		return es_suelo or clave.contains("muro")
	return not es_suelo and (clave.contains("mueble") or clave.contains("objeto") or clave.contains("escalera") or clave.contains("puerta"))

func _colocar_asset_en_tile(tile: Vector2i, clave: String) -> Node2D:
	if interior == null or clave == "" or not _asset_permitido_en_modo(clave):
		return null
	var datos_bloqueo := Assets.datos(clave)
	var es_base_bloqueo := str(datos_bloqueo.get("tipo", "")) == "atlas_tile" or clave.contains("muro")
	var capa_bloqueo := "base" if es_base_bloqueo else "objetos"
	if bool(_capas_bloqueadas.get(capa_bloqueo, false)):
		return null
	if tile.x < 0 or tile.y < 0 or tile.x >= _ancho_editor or tile.y >= _alto_editor:
		return null
	var huella: Vector2i = Assets.huella(clave)
	var datos := Assets.datos(clave)
	var es_suelo := str(datos.get("tipo", "")) == "atlas_tile"
	var rol_nuevo := "suelo" if es_suelo else ("muro" if clave.contains("muro") else ("transicion" if clave.contains("escalera") or clave.contains("puerta") else "mueble"))
	# Un asset ocultado por BORRAR BASE/OBJETOS es un slot reutilizable, no una
	# invitación a crear otro nodo encima. Esto evita stacking al reconstruir la
	# sala después de limpiar una capa.
	var reutilizado := _reactivar_slot_oculto(tile, huella, rol_nuevo, clave)
	if reutilizado != null:
		_seleccionado = reutilizado
		return reutilizado
	if es_suelo:
		for id in _orden_ids:
			var piso: Node2D = _elementos.get(id)
			if piso == null or not is_instance_valid(piso) or str(piso.get_meta("layout_role", "")) != "suelo":
				continue
			if piso.get_meta("layout_casilla", Vector2i(-999, -999)) == tile:
				_aplicar_asset(piso, clave)
				piso.visible = true
				return piso
	else:
		for id in _orden_ids:
			var existente: Node2D = _elementos.get(id)
			if existente == null or not is_instance_valid(existente) or not existente.visible:
				continue
			var rol_existente := str(existente.get_meta("layout_role", ""))
			if rol_existente != "mueble" and rol_existente != "transicion":
				continue
			var origen: Vector2i = existente.get_meta("layout_casilla", Vector2i(-999, -999))
			var otra_huella: Vector2i = existente.get_meta("layout_huella", Vector2i.ONE)
			if _rect_tiles_solapan(tile, huella, origen, otra_huella):
				return null
	var es_transicion := clave.contains("escalera") or clave.contains("puerta")
	var nodo: Node2D = TransicionZonaScript.new() if es_transicion else Node2D.new()
	nodo.name = "AssetEditor_%03d" % _siguiente_asset_id
	nodo.position = Iso.centro_v(tile)
	nodo.set_meta("layout_id", "asset_editor_%03d" % _siguiente_asset_id)
	nodo.set_meta("layout_role", "transicion" if es_transicion else rol_nuevo)
	nodo.set_meta("layout_transition_type", "zona" if es_transicion else "")
	nodo.set_meta("layout_asset", clave)
	nodo.set_meta("layout_casilla", tile)
	nodo.set_meta("layout_huella", huella)
	nodo.set_meta("layout_solido", false)
	nodo.set_meta("layout_base_position", nodo.position)
	nodo.set_meta("layout_base_rotation", 0.0)
	if es_transicion:
		var transicion := nodo as TransicionZona
		transicion.casilla_propia = tile
		transicion.destino_zona = _destino_transicion_por_defecto()
		transicion.entrada_destino = Vector2i(1, 1)
		transicion.accion = "Usar"
		transicion.usar_asset(clave)
		nodo.set_meta("layout_destino_zona", transicion.destino_zona)
		nodo.set_meta("layout_entrada_destino", transicion.entrada_destino)
		nodo.set_meta("layout_accion", transicion.accion)
	else:
		var sprite := _crear_sprite_asset(clave)
		nodo.add_child(sprite)
	interior.add_child(nodo)
	if es_transicion and interior.has_method("registrar_transicion_editor"):
		interior.registrar_transicion_editor(nodo as TransicionZona)
	_elementos[nodo.get_meta("layout_id")] = nodo
	_orden_ids.append(str(nodo.get_meta("layout_id")))
	_orden_ids.sort()
	_seleccionado = nodo
	_siguiente_asset_id += 1
	return nodo

func _destino_transicion_por_defecto() -> String:
	if interior == null or interior.definicion == null:
		return ""
	var candidatos: Array[String] = []
	for clave in ["interior_capitania_pb", "interior_capitania_pa", "interior_herreria_pb", "interior_taberna_pb"]:
		if clave != interior.definicion.id and BaseDeDatos.interior(clave) != null:
			candidatos.append(clave)
	return candidatos[0] if not candidatos.is_empty() else ""

func _confirmar_posicion_transiciones() -> void:
	var cambio := false
	for nodo in _seleccionados:
		if nodo == null or not is_instance_valid(nodo) or str(nodo.get_meta("layout_role", "")) != "transicion":
			continue
		var local := interior.to_local(nodo.global_position)
		var casilla := Iso.a_tile(local)
		if casilla.x < 0 or casilla.y < 0 or casilla.x >= _ancho_editor or casilla.y >= _alto_editor:
			_actualizar_estado("Transición fuera de la sala; posición cancelada")
			_reposicionar_transicion(nodo, nodo.get_meta("layout_casilla", Vector2i.ZERO))
		else:
			_reposicionar_transicion(nodo, casilla)
		cambio = true
	if cambio:
		_aplicar_tamano_visual()

func _reposicionar_transicion(nodo: Node2D, casilla: Vector2i) -> void:
	nodo.set_meta("layout_casilla", casilla)
	nodo.position = Iso.centro_v(casilla)
	if nodo is TransicionZona:
		(nodo as TransicionZona).casilla_propia = casilla
		(nodo as TransicionZona).establecer_casillas_interaccion(_casillas_de_acceso_editor(casilla))
	elif nodo is Puerta:
		(nodo as Puerta).casilla_propia = casilla

func _casillas_de_acceso_editor(origen: Vector2i) -> Array[Vector2i]:
	var salida: Array[Vector2i] = []
	for candidato in [origen + Vector2i(1, 0), origen + Vector2i(-1, 0), origen + Vector2i(0, 1), origen + Vector2i(0, -1)]:
		if candidato.x >= 0 and candidato.y >= 0 and candidato.x < _ancho_editor and candidato.y < _alto_editor:
			if interior.transitable == null or interior.transitable.puede_pisar(candidato):
				salida.append(candidato)
	return salida if not salida.is_empty() else [origen]

func _reactivar_slot_oculto(tile: Vector2i, huella: Vector2i, rol: String, clave: String) -> Node2D:
	for id in _orden_ids:
		var candidato: Node2D = _elementos.get(id)
		if candidato == null or not is_instance_valid(candidato) or candidato.visible:
			continue
		if str(candidato.get_meta("layout_role", "")) != rol:
			continue
		var origen: Vector2i = candidato.get_meta("layout_casilla", Vector2i(-999, -999))
		var huella_anterior: Vector2i = candidato.get_meta("layout_huella", Vector2i.ONE)
		var coincide := origen == tile if rol == "suelo" or rol == "muro" else _rect_tiles_solapan(tile, huella, origen, huella_anterior)
		if not coincide:
			continue
		_aplicar_asset(candidato, clave)
		candidato.position = Iso.centro_v(tile)
		candidato.set_meta("layout_casilla", tile)
		candidato.set_meta("layout_huella", huella)
		candidato.set_meta("layout_base_position", candidato.position)
		candidato.set_meta("layout_oculto_por_boton", false)
		if candidato is TransicionZona:
			var transicion := candidato as TransicionZona
			transicion.casilla_propia = tile
			transicion.establecer_casillas_interaccion(_casillas_de_acceso_editor(tile))
		elif candidato is Puerta:
			(candidato as Puerta).casilla_propia = tile
		candidato.process_mode = Node.PROCESS_MODE_INHERIT
		candidato.self_modulate = Color.WHITE
		candidato.visible = true
		return candidato
	return null

func _rect_tiles_solapan(origen_a: Vector2i, huella_a: Vector2i, origen_b: Vector2i, huella_b: Vector2i) -> bool:
	return origen_a.x < origen_b.x + huella_b.x and origen_a.x + huella_a.x > origen_b.x and origen_a.y < origen_b.y + huella_b.y and origen_a.y + huella_a.y > origen_b.y

func _iniciar_region_colocacion(posicion: Vector2) -> void:
	_seleccionando_region_colocacion = true
	_region_colocacion_inicio = get_global_mouse_position()
	_region_colocacion_actual = _region_colocacion_inicio
	_actualizar_estado("Arrastra para colocar varias copias de %s" % _nombre_corto(_asset_activo))

func _finalizar_region_colocacion() -> void:
	_seleccionando_region_colocacion = false
	if interior == null or _asset_activo == "":
		return
	var inicio := Iso.a_tile(interior.to_local(_region_colocacion_inicio))
	var fin := Iso.a_tile(interior.to_local(_region_colocacion_actual))
	var min_x := mini(inicio.x, fin.x)
	var max_x := maxi(inicio.x, fin.x)
	var min_y := mini(inicio.y, fin.y)
	var max_y := maxi(inicio.y, fin.y)
	var colocados := 0
	_guardar_historial()
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _colocar_asset_en_tile(Vector2i(x, y), _asset_activo) != null:
				colocados += 1
	if colocados == 0:
		_actualizar_estado("No había casillas disponibles en la zona")
	else:
		_actualizar_estado("Colocadas %d copias de %s" % [colocados, _nombre_corto(_asset_activo)])
	queue_redraw()

func _alternar_referencia() -> void:
	_referencia_visible = not _referencia_visible
	if referencia != null and is_instance_valid(referencia):
		referencia.visible = _referencia_visible
	if _boton_referencia != null:
		_boton_referencia.text = "▼ OCULTAR REFERENCIA" if _referencia_visible else "▶ MOSTRAR REFERENCIA"
	_actualizar_estado("Referencia visual %s" % ("visible" if _referencia_visible else "oculta"))
	queue_redraw()

func _pedir_borrado_modo(modo: int) -> void:
	_modo_borrado_pendiente = modo
	if (modo == ModoEditor.BASE and _base_oculta_por_boton) or (modo == ModoEditor.OBJETOS and _objetos_ocultos_por_boton):
		_restaurar_todo_modo(modo)
		return
	# Acción directa y reversible: el editor no abandona esta instancia.
	_aplicar_borrado_modo(modo)

func _borrar_todo_modo() -> void:
	# La confirmación no cambia de escena ni cambia de modo. Solo modifica la
	# visibilidad de la capa elegida dentro de este editor local.
	# Se difiere un frame para no modificar nodos del interior durante la señal
	# "confirmed" del diálogo; esto evita que Godot cierre/descartе la vista
	# embebida mientras el control todavía está procesando el clic.
	call_deferred("_aplicar_borrado_modo", _modo_borrado_pendiente)

func _aplicar_borrado_modo(modo: int) -> void:
	if not is_inside_tree() or interior == null or not is_instance_valid(interior):
		return
	_guardar_respaldo_automatico("borrado de capa")
	_guardar_historial()
	var ocultados := 0
	# No usar un literal tipado dentro de un ternario: Godot lo interpreta como
	# Array sin tipar y provoca "Trying to assign Array to Array[String]" al
	# pulsar BORRAR BASE. Construimos la lista explícitamente.
	var roles_permitidos: Array[String] = []
	if modo == ModoEditor.BASE:
		roles_permitidos.append("suelo")
		roles_permitidos.append("muro")
		roles_permitidos.append("borde")
	else:
		roles_permitidos.append("mueble")
		roles_permitidos.append("transicion")
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo) or not nodo.visible:
			continue
		if roles_permitidos.has(str(nodo.get_meta("layout_role", ""))):
			# Eliminación lógica del editor: el nodo deja de renderizarse,
			# seleccionarse y ocupar un slot. Se conserva fuera del árbol lógico
			# para poder restaurarlo o reutilizarlo sin crear stacking.
			nodo.visible = false
			nodo.process_mode = Node.PROCESS_MODE_DISABLED
			nodo.set_meta("layout_oculto_por_boton", true)
			nodo.self_modulate = Color.WHITE
			ocultados += 1
	if modo == ModoEditor.BASE:
		if not _base_oculta_por_boton:
			_rejilla_muros_antes_borrado = _mostrar_rejilla_muros
			_rejilla_suelo_antes_borrado = _mostrar_rejilla
			_subrejilla_suelo_antes_borrado = _mostrar_subrejilla
			# El lienzo limpio no debe conservar guías que parezcan un segundo
			# piso ni paneles murales fantasma debajo del nuevo diseño.
			_mostrar_rejilla_muros = false
			_mostrar_rejilla = false
			_mostrar_subrejilla = false
		_base_oculta_por_boton = true
		if _boton_borrar_base != null:
			_boton_borrar_base.text = "RESTAURAR BASE"
	else:
		_objetos_ocultos_por_boton = true
		if _boton_borrar_objetos != null:
			_boton_borrar_objetos.text = "RESTAURAR OBJETOS"
	_limpiar_seleccion(false)
	_actualizar_estado("Ocultados %d assets. Modo %s activo; la estructura queda lista para colocar nuevos assets." % [ocultados, _nombre_modo_editor()])
	queue_redraw()

func _restaurar_todo_modo(modo: int) -> void:
	_guardar_historial()
	var roles_permitidos: Array[String] = []
	if modo == ModoEditor.BASE:
		roles_permitidos.append("suelo")
		roles_permitidos.append("muro")
		roles_permitidos.append("borde")
	else:
		roles_permitidos.append("mueble")
		roles_permitidos.append("transicion")
	var restaurados := 0
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo):
			continue
		if roles_permitidos.has(str(nodo.get_meta("layout_role", ""))):
			# Restaurar solo la apariencia que controla este botón.
			nodo.self_modulate = Color.WHITE
			nodo.visible = true
			nodo.process_mode = Node.PROCESS_MODE_INHERIT
			nodo.set_meta("layout_oculto_por_boton", false)
			restaurados += 1
	if modo == ModoEditor.BASE:
		_mostrar_rejilla_muros = _rejilla_muros_antes_borrado
		_mostrar_rejilla = _rejilla_suelo_antes_borrado
		_mostrar_subrejilla = _subrejilla_suelo_antes_borrado
		_base_oculta_por_boton = false
		if _boton_borrar_base != null:
			_boton_borrar_base.text = "BORRAR BASE"
	else:
		_objetos_ocultos_por_boton = false
		if _boton_borrar_objetos != null:
			_boton_borrar_objetos.text = "BORRAR OBJETOS"
	_actualizar_estado("Restaurados %d assets. Modo %s activo." % [restaurados, _nombre_modo_editor()])
	queue_redraw()

func _crear_sprite_asset(clave: String) -> Sprite2D:
	var sprite := Assets.sprite(clave)
	var datos := Assets.datos(clave)
	if str(datos.get("tipo", "")) != "atlas_tile":
		return sprite
	var textura := Assets.textura(clave)
	var celda: Array = datos.get("celda_fisica", [128, 64])
	if textura != null and celda.size() >= 2:
		var atlas := AtlasTexture.new()
		atlas.atlas = Assets.textura_celda(clave, 0, Vector2i(int(celda[0]), int(celda[1])))
		atlas.region = Rect2(0.0, 0.0, float(celda[0]), float(celda[1]))
		sprite.texture = atlas
		sprite.centered = true
		sprite.offset = Vector2.ZERO
	return sprite

func _cancelar_asset_activo() -> void:
	_asset_activo = ""
	_colocando_asset = false
	_arrastrando_asset = false
	if _asset_preview != null and is_instance_valid(_asset_preview):
		_asset_preview.queue_free()
	_asset_preview = null

func _alternar_modo_relleno_muro() -> void:
	if _modo_editor != ModoEditor.BASE:
		_actualizar_estado("Rellenar muro solo esta disponible en modo BASE")
		return
	_modo_relleno_muro = not _modo_relleno_muro
	_seleccionando_relleno_muro = false
	if _modo_relleno_muro and not _asegurar_asset_muro_activo():
		_modo_relleno_muro = false
		_actualizar_estado("No hay un asset de muro recto disponible")
		return
	if not _modo_relleno_muro:
		_actualizar_estado("Rellenar muro desactivado")
	else:
		_actualizar_estado("Rellenar muro activo: %s · arrastra con RMB dentro del suelo" % _nombre_corto(_asset_activo))
	if _boton_relleno_muro != null:
		_boton_relleno_muro.text = "RELLENAR MURO: ON" if _modo_relleno_muro else "RELLENAR MURO: OFF"
	if _boton_relleno_muro_paleta != null:
		_boton_relleno_muro_paleta.text = "RELLENAR MURO [M]: ON" if _modo_relleno_muro else "RELLENAR MURO [M]: OFF"
	queue_redraw()

func _asegurar_asset_muro_activo() -> bool:
	if _asset_activo.contains("muro") and Assets.existe(_asset_activo):
		return true
	if interior != null and interior.definicion != null:
		var definido := str(interior.definicion.asset_muro_norte)
		if definido != "" and Assets.existe(definido):
			_seleccionar_asset_paleta(definido)
			return true
	var candidatos := _assets_de_categoria(0)
	for clave in candidatos:
		if clave.contains("muro_norte") and not clave.contains("esquina") and not clave.contains("borde") and not clave.contains("pilar"):
			_seleccionar_asset_paleta(clave)
			return true
	for clave in candidatos:
		if clave.contains("muro_oeste") and not clave.contains("esquina") and not clave.contains("borde") and not clave.contains("pilar"):
			_seleccionar_asset_paleta(clave)
			return true
	return false

func _iniciar_relleno_muro(posicion: Vector2) -> void:
	if _asset_activo == "" or not _asset_activo.contains("muro"):
		if not _asegurar_asset_muro_activo():
			_actualizar_estado("Selecciona primero un asset de muro recto en la paleta")
			return
	_seleccionando_relleno_muro = true
	_relleno_muro_inicio = posicion
	_relleno_muro_actual = posicion
	_actualizar_estado("Arrastra el rectangulo del perimetro de muro y suelta RMB")

func _cancelar_relleno_muro() -> void:
	_seleccionando_relleno_muro = false
	_relleno_muro_inicio = Vector2.ZERO
	_relleno_muro_actual = Vector2.ZERO
	queue_redraw()

func _finalizar_relleno_muro() -> void:
	_seleccionando_relleno_muro = false
	if interior == null or _asset_activo == "":
		return
	var inicio := Iso.a_tile(interior.to_local(_relleno_muro_inicio))
	var fin := Iso.a_tile(interior.to_local(_relleno_muro_actual))
	var min_x := clampi(mini(inicio.x, fin.x), 0, _ancho_editor - 1)
	var max_x := clampi(maxi(inicio.x, fin.x), 0, _ancho_editor - 1)
	var min_y := clampi(mini(inicio.y, fin.y), 0, _alto_editor - 1)
	var max_y := clampi(maxi(inicio.y, fin.y), 0, _alto_editor - 1)
	if max_x - min_x < 1 or max_y - min_y < 1:
		_actualizar_estado("El perimetro necesita al menos 2 x 2 casillas")
		queue_redraw()
		return
	_guardar_respaldo_automatico("relleno de muro")
	_guardar_historial()
	var relleno_id := "wall_fill_%d" % Time.get_ticks_msec()
	var creados := 0
	for x in range(min_x, max_x + 1):
		creados += _colocar_segmento_muro(Vector2i(x, min_y), _asset_para_perimetro(_asset_activo, true), false, relleno_id)
		creados += _colocar_segmento_muro(Vector2i(x, max_y), _asset_para_perimetro(_asset_activo, true), true, relleno_id)
	for y in range(min_y + 1, max_y):
		creados += _colocar_segmento_muro(Vector2i(min_x, y), _asset_para_perimetro(_asset_activo, false), false, relleno_id)
		creados += _colocar_segmento_muro(Vector2i(max_x, y), _asset_para_perimetro(_asset_activo, false), true, relleno_id)
	_actualizar_estado("Perimetro creado: %d segmentos alineados a la cuadricula" % creados)
	_aplicar_tamano_visual()
	queue_redraw()

func _asset_para_perimetro(preferido: String, horizontal: bool) -> String:
	if interior == null or interior.definicion == null:
		return preferido
	var alternativo := interior.definicion.asset_muro_oeste if horizontal else interior.definicion.asset_muro_norte
	if preferido.contains("muro_esquina") or preferido.contains("muro_borde") or preferido.contains("pilar"):
		return alternativo if alternativo != "" and Assets.existe(alternativo) else preferido
	if (horizontal and preferido.contains("muro_norte")) or (not horizontal and preferido.contains("muro_oeste")):
		return alternativo if alternativo != "" and Assets.existe(alternativo) else preferido
	return preferido

func _clave_muro_para_eje(eje: String) -> String:
	if interior == null or interior.definicion == null:
		return _asset_activo
	if eje == "esquina":
		var esquina := str(interior.definicion.asset_muro_esquina)
		return esquina if esquina != "" and Assets.existe(esquina) else _asset_activo
	var clave := str(interior.definicion.asset_muro_oeste if eje == "x" else interior.definicion.asset_muro_norte)
	return clave if clave != "" and Assets.existe(clave) else _asset_activo

func _eje_muro_celda(casilla: Vector2i) -> String:
	if casilla == Vector2i.ZERO:
		return "esquina"
	if casilla.y == 0:
		return "x"
	if casilla.x == 0:
		return "y"
	return ""

func _buscar_muro_en_celda(casilla: Vector2i, eje: String) -> Node2D:
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo):
			continue
		if str(nodo.get_meta("layout_role", "")) not in ["muro", "borde"]:
			continue
		if nodo.get_meta("layout_casilla", Vector2i(-999, -999)) != casilla:
			continue
		var eje_nodo := str(nodo.get_meta("layout_wall_axis", _eje_muro(str(nodo.get_meta("layout_asset", "")), casilla)))
		if eje_nodo == eje or (casilla == Vector2i.ZERO and eje_nodo == "esquina"):
			return nodo
	return null

func _puntos_celda_muro_global(casilla: Vector2i, eje: String) -> PackedVector2Array:
	var clave := _clave_muro_para_eje(eje)
	var inicio := _posicion_muro_global(casilla, clave)
	var fin := inicio + _direccion_arista_muro(eje if eje != "esquina" else "x")
	var altura := Vector2(0.0, -ALTURA_REJILLA_MURO_FISICA)
	return PackedVector2Array([inicio, fin, fin + altura, inicio + altura])

func _muro_celda_bajo_cursor(mouse: Vector2) -> Dictionary:
	if _modo_editor != ModoEditor.BASE or not _mostrar_rejilla_muros or interior == null:
		return {}
	var candidatos: Array[Dictionary] = []
	# La esquina pertenece a ambos ejes, pero se representa una sola vez.
	candidatos.append({"casilla": Vector2i.ZERO, "eje": "esquina"})
	for x in _ancho_editor:
		if x > 0:
			candidatos.append({"casilla": Vector2i(x, 0), "eje": "x"})
	for y in range(1, _alto_editor):
		candidatos.append({"casilla": Vector2i(0, y), "eje": "y"})
	for candidato in candidatos:
		var puntos_globales := _puntos_celda_muro_global(candidato.casilla, candidato.eje)
		if Geometry2D.is_point_in_polygon(mouse, puntos_globales):
			candidato["nodo"] = _buscar_muro_en_celda(candidato.casilla, candidato.eje)
			return candidato
	return {}

func _gestionar_clic_celda_muro(posicion: Vector2) -> bool:
	if _modo_editor != ModoEditor.BASE or not _mostrar_rejilla_muros:
		return false
	var info := _muro_celda_bajo_cursor(get_global_mouse_position())
	if info.is_empty():
		return false
	var casilla: Vector2i = info.casilla
	var eje: String = info.eje
	var nodo: Node2D = info.get("nodo") as Node2D
	if _colocando_asset and _asset_activo.contains("muro"):
		_guardar_historial()
		var creado := _colocar_segmento_muro_celda(casilla, eje)
		if creado != null:
			_seleccionado = creado
			_seleccionados = [creado]
			_actualizar_estado("Muro colocado en %s:%d. Puedes seguir colocando o pulsar RMB para cancelar" % [eje, _indice_muro_celda(casilla, eje)])
			_actualizar_panel()
			queue_redraw()
		return true
	if nodo != null and is_instance_valid(nodo):
		_seleccionar_bajo_cursor(nodo)
		_actualizar_estado("Muro %s seleccionado. Arrastra para mover o pulsa Supr para quitarlo" % _nombre_corto(str(nodo.get_meta("layout_asset", "muro"))))
		return true
	_actualizar_estado("Celda mural vacia: selecciona un muro en la paleta y haz clic para colocarlo")
	return true

func _indice_muro_celda(casilla: Vector2i, eje: String) -> int:
	return casilla.x if eje == "x" else casilla.y

func _colocar_segmento_muro_celda(casilla: Vector2i, eje: String) -> Node2D:
	if eje == "":
		return null
	var clave := _asset_activo if _asset_activo.contains("muro") else _clave_muro_para_eje(eje)
	if eje == "esquina":
		clave = _clave_muro_para_eje(eje)
	if clave == "" or not Assets.existe(clave):
		return null
	var existente := _buscar_muro_en_celda(casilla, eje)
	var nodo := existente
	if nodo == null:
		nodo = _crear_base_editor(casilla, "muro", clave)
	else:
		_aplicar_asset(nodo, clave)
	nodo.position = _posicion_muro_local(casilla, clave)
	nodo.set_meta("layout_casilla", casilla)
	nodo.set_meta("layout_base_position", nodo.position)
	nodo.set_meta("layout_wall_axis", eje)
	nodo.set_meta("layout_solido", true)
	nodo.set_meta("layout_oculto_por_boton", false)
	nodo.visible = true
	nodo.process_mode = Node.PROCESS_MODE_INHERIT
	nodo.self_modulate = Color.WHITE
	return nodo

func _colocar_segmento_muro(casilla: Vector2i, clave: String, espejado: bool, relleno_id: String) -> int:
	if clave == "" or not Assets.existe(clave):
		return 0
	var nodo := _buscar_base_en_casilla(casilla, "muro")
	if nodo == null:
		nodo = _crear_base_editor(casilla, "muro", clave)
	else:
		_aplicar_asset(nodo, clave)
		nodo.visible = true
		nodo.process_mode = Node.PROCESS_MODE_INHERIT
	nodo.set_meta("layout_oculto_por_boton", false)
	nodo.position = _posicion_muro_local(casilla, clave)
	nodo.set_meta("layout_casilla", casilla)
	nodo.set_meta("layout_base_position", nodo.position)
	nodo.set_meta("layout_wall_fill_id", relleno_id)
	nodo.set_meta("layout_wall_edge", "perimetro")
	nodo.set_meta("layout_wall_axis", _eje_muro(clave, casilla))
	nodo.scale = Vector2(-1.0 if espejado else 1.0, 1.0)
	return 1

func _estilo_panel(fondo: Color, borde: Color, grosor: int, alfa: float) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(fondo, alfa)
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.corner_radius_top_left = 8
	estilo.corner_radius_top_right = 8
	estilo.corner_radius_bottom_left = 8
	estilo.corner_radius_bottom_right = 8
	estilo.content_margin_left = 12.0
	estilo.content_margin_right = 12.0
	estilo.content_margin_top = 10.0
	estilo.content_margin_bottom = 10.0
	return estilo

func _ajustar_zoom_sala(delta: float) -> void:
	_zoom_sala = clampf(_zoom_sala + delta, ZOOM_SALA_MIN, ZOOM_SALA_MAX)
	if interior != null:
		interior.scale = Vector2.ONE * _zoom_sala
	_actualizar_estado("Zoom de sala: %d%%" % round(_zoom_sala * 100.0))
	_actualizar_panel()
	queue_redraw()

func _ajustar_zoom_referencia(delta: float) -> void:
	_zoom_referencia = clampf(_zoom_referencia + delta, ZOOM_REFERENCIA_MIN, ZOOM_REFERENCIA_MAX)
	if referencia != null:
		referencia.scale = Vector2.ONE * _zoom_referencia
	_actualizar_estado("Zoom de referencia: %d%%" % round(_zoom_referencia * 100.0))
	_actualizar_panel()
	queue_redraw()

func _elemento_bajo_cursor() -> Node2D:
	var mouse := get_global_mouse_position()
	# Primero se buscan objetos reales y transiciones. Si el cursor está sobre
	# un objeto, la baldosa del suelo no debe ganar la selección.
	var mejor := _elemento_bajo_cursor_en_roles(mouse, false)
	if mejor != null:
		return mejor
	return _elemento_bajo_cursor_en_roles(mouse, true)

func _elemento_bajo_cursor_en_roles(mouse: Vector2, solo_suelo: bool) -> Node2D:
	var exacto: Node2D = null
	var exacto_puntuacion := -INF
	var amplio: Node2D = null
	var amplio_puntuacion := -INF
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo) or not nodo.visible:
			continue
		var es_suelo := str(nodo.get_meta("layout_role", "")) == "suelo"
		if es_suelo != solo_suelo:
			continue
		if not _es_editable_en_modo(nodo):
			continue
		var prioridad := 2.0 if str(nodo.get_meta("layout_role", "")) == "mueble" else 1.0
		var visual := _rect_visual_global(nodo)
		var rect := _rect_seleccion_global(nodo)
		if visual.has_point(mouse):
			var puntuacion_visual := prioridad * 100000.0 + nodo.global_position.y * 10.0 - visual.get_area()
			if puntuacion_visual > exacto_puntuacion:
				exacto = nodo
				exacto_puntuacion = puntuacion_visual
		elif rect.has_point(mouse):
			var puntuacion_amplia := prioridad * 100000.0 + nodo.global_position.y * 10.0 - rect.get_area() * 0.01
			if puntuacion_amplia > amplio_puntuacion:
				amplio = nodo
				amplio_puntuacion = puntuacion_amplia
	return exacto if exacto != null else amplio

func _mouse_sobre_interfaz(posicion: Vector2) -> bool:
	for control in [_panel, _panel_comandos, _paleta, _boton_panel, _boton_comandos, _boton_paleta, _boton_mover_paleta, _boton_mover_panel, _boton_mover_comandos, _boton_mover_referencia]:
		if control != null and is_instance_valid(control) and control.visible and control.get_global_rect().has_point(posicion):
			return true
	return false

func _rect_visual_global(nodo: Node2D) -> Rect2:
	var sprite := _sprite_principal(nodo)
	if sprite == null or sprite.texture == null:
		return Rect2(nodo.global_position - Vector2(20, 20), Vector2(40, 40))
	var local := sprite.get_rect()
	var transform := sprite.get_global_transform_with_canvas()
	var esquinas := PackedVector2Array([
		transform * local.position,
		transform * Vector2(local.end.x, local.position.y),
		transform * Vector2(local.position.x, local.end.y),
		transform * local.end,
	])
	var minimo := esquinas[0]
	var maximo := esquinas[0]
	for punto in esquinas:
		minimo.x = minf(minimo.x, punto.x)
		minimo.y = minf(minimo.y, punto.y)
		maximo.x = maxf(maximo.x, punto.x)
		maximo.y = maxf(maximo.y, punto.y)
	return Rect2(minimo, maximo - minimo)

func _rect_seleccion_global(nodo: Node2D) -> Rect2:
	# Área cómoda para seleccionar en el editor. No participa en colisiones,
	# transitabilidad ni en la huella guardada del objeto.
	var visual := _rect_visual_global(nodo)
	var rol := str(nodo.get_meta("layout_role", ""))
	if rol == "suelo":
		return visual
	var casilla: Variant = nodo.get_meta("layout_casilla", Vector2i.ZERO)
	var huella: Variant = nodo.get_meta("layout_huella", Vector2i.ONE)
	# Rectangulo amplio solo para seleccionar en el editor; nunca es colision.
	var extra := Vector2(18.0, 18.0)
	if casilla is Vector2i and huella is Vector2i:
		extra += Vector2(float(maxi(0, huella.x - 1) * Iso.ANCHO),
			float(maxi(0, huella.y - 1) * Iso.ALTO)) * 0.5
	var tamano_minimo := Vector2(84.0, 84.0)
	var centro := visual.get_center()
	var tamano := Vector2(maxf(visual.size.x + extra.x * 2.0, tamano_minimo.x),
		maxf(visual.size.y + extra.y * 2.0, tamano_minimo.y))
	return Rect2(centro - tamano * 0.5, tamano)

func _seleccionar_bajo_cursor(mejor: Node2D = null) -> void:
	if mejor == null:
		mejor = _elemento_bajo_cursor()
	if mejor == null:
		_actualizar_estado("Ningun elemento bajo el cursor")
		return
	var mouse := get_global_mouse_position()
	if not _seleccionados.has(mejor):
		_seleccionados.clear()
		_seleccionados.append(mejor)
	_seleccionado = mejor
	_arrastre_offset = _seleccionado.global_position - mouse
	_arrastre_offsets.clear()
	for nodo in _seleccionados:
		if nodo != null and is_instance_valid(nodo):
			_arrastre_offsets[str(nodo.get_meta("layout_id", ""))] = nodo.global_position - mouse
	_arrastrando = true
	_guardar_historial()
	_actualizar_calibrador_desde_seleccion()
	_actualizar_estado("Seleccionados: %d" % _seleccionados.size())

func _iniciar_marco_seleccion(posicion: Vector2) -> void:
	_seleccionando_marco = true
	_marco_inicio = get_global_mouse_position()
	_marco_actual = _marco_inicio
	_limpiar_seleccion(false)
	_actualizar_estado("Arrastra para seleccionar varios objetos")

func _finalizar_marco_seleccion() -> void:
	_seleccionando_marco = false
	var marco := Rect2(_marco_inicio, _marco_actual - _marco_inicio).abs()
	if marco.size.length() < 8.0:
		var bajo := _elemento_bajo_cursor()
		if bajo != null:
			_seleccionados = [bajo]
			_seleccionado = bajo
	else:
		for id in _orden_ids:
			var nodo: Node2D = _elementos.get(id)
			if nodo == null or not is_instance_valid(nodo) or not nodo.visible:
				continue
			if not _es_editable_en_modo(nodo):
				continue
			if marco.intersects(_rect_seleccion_global(nodo)):
				_seleccionados.append(nodo)
		if not _seleccionados.is_empty():
			_seleccionado = _seleccionados[0]
	if _seleccionados.is_empty():
		_seleccionado = null
		_actualizar_estado("Ningun objeto dentro del marco")
	else:
		_actualizar_estado("Seleccionados: %d objetos" % _seleccionados.size())
	_actualizar_calibrador_desde_seleccion()
	queue_redraw()

func _copiar_seleccion() -> void:
	_portapapeles_layout.clear()
	if _seleccionados.is_empty():
		_actualizar_estado("No hay objetos seleccionados para copiar")
		return
	var origen := _seleccionados[0].global_position
	for nodo in _seleccionados:
		if nodo == null or not is_instance_valid(nodo):
			continue
		_portapapeles_layout.append(_capturar_elemento_para_copia(nodo, nodo.global_position - origen))
	_actualizar_estado("Copiados %d elementos" % _portapapeles_layout.size())

func _capturar_elemento_para_copia(nodo: Node2D, delta: Vector2) -> Dictionary:
	return {
		"asset": str(nodo.get_meta("layout_asset", "")),
		"rol": str(nodo.get_meta("layout_role", "mueble")),
		"delta": [delta.x, delta.y],
		"calibracion": nodo.get_meta("layout_calibracion", {}).duplicate(true),
		"altura_muro": _altura_muro_de_nodo(nodo),
		"destino_zona": str(nodo.get_meta("layout_destino_zona", "")),
		"entrada_destino": _serializar_vector2i(nodo.get_meta("layout_entrada_destino", Vector2i.ONE)),
		"accion": str(nodo.get_meta("layout_accion", "Usar")),
	}

func _pegar_seleccion() -> void:
	if _portapapeles_layout.is_empty() or interior == null:
		_actualizar_estado("Portapapeles vacio")
		return
	var centro := get_global_mouse_position()
	var creados: Array[Node2D] = []
	_guardar_historial()
	for datos in _portapapeles_layout:
		var delta: Array = datos.get("delta", [0.0, 0.0])
		var posicion := _ajustar_posicion(centro + Vector2(float(delta[0]), float(delta[1])))
		var local := interior.to_local(posicion)
		var creado := _colocar_asset_en_tile(Iso.a_tile(local), str(datos.get("asset", "")))
		if creado == null:
			continue
		creado.set_meta("layout_calibracion", datos.get("calibracion", {}).duplicate(true))
		creado.set_meta("layout_destino_zona", str(datos.get("destino_zona", "")))
		creado.set_meta("layout_entrada_destino", _deserializar_vector2i(datos.get("entrada_destino", [1, 1])))
		creado.set_meta("layout_accion", str(datos.get("accion", "Usar")))
		if creado is TransicionZona:
			var transicion_pegada := creado as TransicionZona
			transicion_pegada.destino_zona = str(datos.get("destino_zona", ""))
			transicion_pegada.entrada_destino = _deserializar_vector2i(datos.get("entrada_destino", [1, 1]))
			transicion_pegada.accion = str(datos.get("accion", "Usar"))
		_aplicar_calibracion_a_nodo(creado, creado.get_meta("layout_calibracion", {}))
		creados.append(creado)
	_seleccionados = creados
	_seleccionado = creados[0] if not creados.is_empty() else null
	_actualizar_estado("Pegados %d elementos" % creados.size())
	_actualizar_calibrador_desde_seleccion()
	queue_redraw()

func _duplicar_seleccion() -> void:
	_copiar_seleccion()
	if _portapapeles_layout.is_empty():
		return
	# Desplazamiento de seguridad para que la copia se vea y no se apile.
	for datos in _portapapeles_layout:
		var delta: Array = datos.get("delta", [0.0, 0.0])
		datos["delta"] = [float(delta[0]) + 32.0, float(delta[1]) + 32.0]
	_pegar_seleccion()

func _alinear_seleccion(horizontal: bool) -> void:
	if _seleccionados.size() < 2:
		_actualizar_estado("Selecciona al menos dos elementos")
		return
	_guardar_historial()
	var referencia_nodo := _seleccionados[0]
	var objetivo := referencia_nodo.global_position.x if horizontal else referencia_nodo.global_position.y
	for nodo in _seleccionados.slice(1):
		if nodo == null or not is_instance_valid(nodo):
			continue
		var posicion: Vector2 = nodo.global_position
		if horizontal:
			posicion.x = objetivo
		else:
			posicion.y = objetivo
		nodo.global_position = _ajustar_posicion(posicion)
	_actualizar_estado("Seleccion alineada %s" % ("horizontalmente" if horizontal else "verticalmente"))
	queue_redraw()

func _realinear_muros() -> void:
	if interior == null or not is_instance_valid(interior):
		return
	_guardar_historial()
	var corregidos := 0
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo):
			continue
		if str(nodo.get_meta("layout_role", "")) not in ["muro", "borde"]:
			continue
		var casilla: Variant = nodo.get_meta("layout_casilla", null)
		if not casilla is Vector2i:
			continue
		# La casilla lógica es la autoridad. Solo se corrige la posición del
		# nodo; el sprite, la altura, la huella y la calibración permanecen.
		nodo.global_position = _posicion_muro_global(casilla, str(nodo.get_meta("layout_asset", "")))
		nodo.set_meta("layout_base_position", nodo.position)
		corregidos += 1
	_problemas_editor = _diagnosticar_editor()
	_actualizar_estado("Realineados %d muros/bordes a la cuadricula Iso" % corregidos)
	_actualizar_panel()
	queue_redraw()

func _corregir_ejes_muros() -> void:
	if interior == null or not is_instance_valid(interior) or interior.definicion == null:
		return
	_guardar_historial()
	var corregidos := 0
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo) or not nodo.visible:
			continue
		if str(nodo.get_meta("layout_role", "")) != "muro":
			continue
		var casilla: Variant = nodo.get_meta("layout_casilla", null)
		if not casilla is Vector2i:
			continue
		var esperado := _asset_muro_para_casilla(casilla as Vector2i)
		if esperado == "" or str(nodo.get_meta("layout_asset", "")) == esperado:
			continue
		_aplicar_asset(nodo, esperado)
		corregidos += 1
	_problemas_editor = _diagnosticar_editor()
	_actualizar_estado("Ejes corregidos: %d muro%s" % [corregidos, "" if corregidos == 1 else "s"])
	_actualizar_panel()
	queue_redraw()

func _validar_editor() -> void:
	_problemas_editor = _diagnosticar_editor()
	if _problemas_editor.is_empty():
		if _diagnostico_label != null:
			_diagnostico_label.text = "VALIDADOR: OK · sin problemas"
			_diagnostico_label.add_theme_color_override("font_color", GlobalColors.PALETA["verde_claro"])
		_actualizar_estado("VALIDADO: no se encontraron problemas")
	else:
		if _diagnostico_label != null:
			var visibles := _problemas_editor.slice(0, 3)
			_diagnostico_label.text = "VALIDADOR: %d problema%s\n%s" % [
				_problemas_editor.size(),
				"" if _problemas_editor.size() == 1 else "s",
				"\n".join(visibles),
			]
			_diagnostico_label.add_theme_color_override("font_color", GlobalColors.PALETA["rojo_brillante"])
		_actualizar_estado("VALIDACION: %d problema%s" % [_problemas_editor.size(), "" if _problemas_editor.size() == 1 else "s"])
		print("[Editor] Problemas:\n- " + "\n- ".join(_problemas_editor))
	queue_redraw()

func _diagnosticar_editor() -> Array[String]:
	var problemas: Array[String] = []
	var ocupadas: Dictionary = {}
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo) or not nodo.visible:
			continue
		var rol := str(nodo.get_meta("layout_role", ""))
		var casilla: Variant = nodo.get_meta("layout_casilla", null)
		if casilla is Vector2i:
			if casilla.x < 0 or casilla.y < 0 or casilla.x >= _ancho_editor or casilla.y >= _alto_editor:
				problemas.append("%s está fuera de la sala" % id)
			if rol in ["mueble", "transicion"]:
				var huella: Vector2i = nodo.get_meta("layout_huella", Vector2i.ONE)
				if casilla.x + huella.x > _ancho_editor or casilla.y + huella.y > _alto_editor:
					problemas.append("%s ocupa fuera de la sala (%dx%d)" % [id, huella.x, huella.y])
				for y in huella.y:
					for x in huella.x:
						var celda: Vector2i = casilla + Vector2i(x, y)
						var clave := "%d,%d" % [celda.x, celda.y]
						if ocupadas.has(clave):
							problemas.append("Solape: %s con %s" % [id, ocupadas[clave]])
						else:
							ocupadas[clave] = id
			if rol == "transicion" and str(nodo.get_meta("layout_destino_zona", "")).is_empty():
				problemas.append("Transición %s no tiene destino" % id)
	for id_transicion in _orden_ids:
		var transicion_nodo: Node2D = _elementos.get(id_transicion)
		if transicion_nodo == null or not is_instance_valid(transicion_nodo) or not transicion_nodo.visible:
			continue
		if str(transicion_nodo.get_meta("layout_role", "")) != "transicion":
			continue
		var destino_transicion := str(transicion_nodo.get_meta("layout_destino_zona", "")).strip_edges()
		if destino_transicion.is_empty():
			continue
		var definicion_destino = BaseDeDatos.interior(destino_transicion)
		if definicion_destino == null:
			problemas.append("Transicion %s apunta a zona inexistente: %s" % [id_transicion, destino_transicion])
			continue
		var entrada_destino: Variant = transicion_nodo.get_meta("layout_entrada_destino", Vector2i.ONE)
		if entrada_destino is Vector2i:
			var entrada := entrada_destino as Vector2i
			if entrada.x < 0 or entrada.y < 0 or entrada.x >= definicion_destino.ancho or entrada.y >= definicion_destino.alto:
				problemas.append("Transicion %s tiene entrada fuera de %s" % [id_transicion, destino_transicion])
	var esquinas := _validar_alineacion_muros()
	problemas.append_array(esquinas)
	return problemas

func _muros_desalineados() -> Array[String]:
	var problemas: Array[String] = []
	var muros: Array[Node2D] = []
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo != null and is_instance_valid(nodo) and nodo.visible and str(nodo.get_meta("layout_role", "")) in ["muro", "borde"]:
			muros.append(nodo)
	for i in muros.size():
		for j in range(i + 1, muros.size()):
			var a := muros[i].global_position
			var b := muros[j].global_position
			var dx := absf(a.x - b.x)
			var dy := absf(a.y - b.y)
			if dx < 2.0 and dy > 160.0 or dy < 2.0 and dx > 256.0:
				continue
		# La comprobación completa de continuidad se deja para la relación de casillas.
	return problemas

func _validar_alineacion_muros() -> Array[String]:
	var problemas: Array[String] = []
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo) or not nodo.visible:
			continue
		if str(nodo.get_meta("layout_role", "")) not in ["muro", "borde"]:
			continue
		var casilla: Variant = nodo.get_meta("layout_casilla", null)
		if not casilla is Vector2i or interior == null:
			continue
		var esperado := _posicion_muro_global(casilla, str(nodo.get_meta("layout_asset", "")))
		var diferencia := nodo.global_position.distance_to(esperado)
		if diferencia > 1.5:
			problemas.append("%s desalineado %.1f px" % [id, diferencia])
		if str(nodo.get_meta("layout_role", "")) == "muro" and interior.definicion != null:
			var esperado_asset := _asset_muro_para_casilla(casilla as Vector2i)
			var actual_asset := str(nodo.get_meta("layout_asset", ""))
			if esperado_asset != "" and actual_asset != esperado_asset:
				problemas.append("%s usa eje incorrecto: %s (esperado %s)" % [id, actual_asset, esperado_asset])
	return problemas

func _asset_muro_para_casilla(casilla: Vector2i) -> String:
	if interior == null or interior.definicion == null:
		return ""
	if casilla == Vector2i.ZERO and interior.definicion.asset_muro_esquina != "":
		if Assets.existe(interior.definicion.asset_muro_esquina):
			return interior.definicion.asset_muro_esquina
	if casilla.y == 0:
		return interior.definicion.asset_muro_oeste
	if casilla.x == 0:
		return interior.definicion.asset_muro_norte
	return ""

func _limpiar_seleccion(actualizar: bool = true) -> void:
	_seleccionados.clear()
	_seleccionado = null
	_arrastre_offsets.clear()
	_arrastrando = false
	if _calibrador != null:
		_calibrador.visible = false
	if actualizar:
		_actualizar_estado("Seleccion limpia")

func _actualizar_hover() -> void:
	_hover_muro_casilla = Vector2i(-1, -1)
	_hover_muro_eje = ""
	if _paneando_sala or _paneando_referencia or _vista_limpia:
		_hovered = null
		return
	if _seleccionando_marco:
		_hovered = null
		return
	var info := _muro_celda_bajo_cursor(get_global_mouse_position())
	if not info.is_empty():
		_hover_muro_casilla = info.casilla
		_hover_muro_eje = info.eje
		_hovered = info.get("nodo") as Node2D
		return
	_hovered = _elemento_bajo_cursor()

func _cursor_sobre_referencia() -> bool:
	if referencia == null or not is_instance_valid(referencia) or referencia.texture == null:
		return false
	var tam := Vector2(referencia.texture.get_size()) * referencia.scale.abs()
	var rect := Rect2(referencia.global_position - tam * 0.5, tam)
	return rect.has_point(get_global_mouse_position())

func _iniciar_paneo_sala() -> void:
	if interior == null:
		return
	_paneando_sala = true
	_paneando_referencia = false
	_paneo_mouse_inicio = get_global_mouse_position()
	_paneo_pos_inicio = interior.position

func _iniciar_paneo_referencia() -> void:
	if referencia == null:
		return
	_paneando_referencia = true
	_paneando_sala = false
	_paneo_mouse_inicio = get_global_mouse_position()
	_paneo_pos_inicio = referencia.position

func _iniciar_paneo(event_position: Vector2) -> void:
	if referencia != null and _cursor_sobre_referencia():
		_iniciar_paneo_referencia()
	else:
		_iniciar_paneo_sala()
	_paneo_mouse_inicio = event_position

func _mover_con_teclado(event: InputEventKey) -> void:
	if _seleccionado == null:
		return
	var rol := str(_seleccionado.get_meta("layout_role", ""))
	var usa_media_baldosa := event.alt_pressed and (rol == "suelo" or rol == "muro")
	var paso := 8.0 if event.shift_pressed else 1.0
	if usa_media_baldosa:
		paso = 64.0 if event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT else 32.0
	if event.ctrl_pressed:
		paso = 64.0
	var delta := Vector2.ZERO
	match event.keycode:
		KEY_LEFT: delta.x = -paso
		KEY_RIGHT: delta.x = paso
		KEY_UP: delta.y = -paso
		KEY_DOWN: delta.y = paso
		_: return
	_guardar_historial()
	_seleccionado.position += delta
	_actualizar_estado("Movimiento de media baldosa aplicado" if usa_media_baldosa else "Movimiento aplicado")

func _espejar_horizontal_seleccionado() -> void:
	if _seleccionado == null:
		return
	_guardar_historial()
	_seleccionado.scale.x = -_seleccionado.scale.x
	_actualizar_estado("Espejo horizontal aplicado")

func _voltear_seleccionado() -> void:
	if _seleccionado == null:
		return
	_guardar_historial()
	_seleccionado.scale.y = -_seleccionado.scale.y
	_actualizar_estado("Espejo vertical aplicado")

func _restaurar_seleccionado() -> void:
	if _seleccionado == null:
		return
	_guardar_historial()
	var base: Vector2 = _seleccionado.get_meta("layout_base_position", _seleccionado.position)
	var rol := str(_seleccionado.get_meta("layout_role", ""))
	if rol == "transicion":
		var casilla: Vector2i = _seleccionado.get_meta("layout_casilla", Vector2i.ZERO)
		_seleccionado.position = Iso.centro_v(casilla)
		if _seleccionado is TransicionZona:
			(_seleccionado as TransicionZona).casilla_propia = casilla
			(_seleccionado as TransicionZona).establecer_casillas_interaccion(_casillas_de_acceso_editor(casilla))
	elif rol in ["muro", "borde"]:
		var casilla_muro: Vector2i = _seleccionado.get_meta("layout_casilla", Vector2i.ZERO)
		_seleccionado.position = _posicion_muro_local(casilla_muro, str(_seleccionado.get_meta("layout_asset", "")))
	else:
		_seleccionado.position = base
	_seleccionado.rotation = 0.0
	_seleccionado.scale = Vector2.ONE
	if _es_muro_o_borde(_seleccionado):
		_seleccionado.set_meta("layout_altura_muro", 1)
		_seleccionado.set_meta("layout_calibracion", {})
		_aplicar_calibracion_a_nodo(_seleccionado, {})
	_seleccionado.visible = true
	_seleccionado.process_mode = Node.PROCESS_MODE_INHERIT
	_seleccionado.set_meta("layout_oculto_por_boton", false)
	_actualizar_estado("Elemento restaurado")

func _cambiar_asset(direccion: int) -> void:
	if _seleccionado == null:
		return
	var rol := str(_seleccionado.get_meta("layout_role", ""))
	var candidatos: Array[String] = []
	for clave_cruda in Assets.claves():
		var clave := str(clave_cruda)
		var datos := Assets.datos(clave)
		var tipo := str(datos.get("tipo", ""))
		if rol == "suelo" and tipo == "atlas_tile" and clave.contains("suelo"):
			candidatos.append(clave)
		elif (rol == "muro" or rol == "borde") and tipo == "sprite" and (clave.contains("muro") or clave.contains("borde")):
			candidatos.append(clave)
		elif rol == "mueble" and tipo == "sprite" and clave.contains("herreria"):
			candidatos.append(clave)
	if candidatos.is_empty():
		_actualizar_estado("No hay assets alternativos para este elemento")
		return
	candidatos.sort()
	var actual := str(_seleccionado.get_meta("layout_asset", candidatos[0]))
	var posicion := candidatos.find(actual)
	if posicion < 0:
		posicion = 0
	posicion = posmod(posicion + direccion, candidatos.size())
	var nueva_clave := candidatos[posicion]
	var sprite := _sprite_principal(_seleccionado)
	if sprite == null:
		_actualizar_estado("El elemento no tiene Sprite2D intercambiable")
		return
	_guardar_historial()
	if rol == "suelo":
		var nueva_textura := Assets.textura(nueva_clave)
		var datos_nuevo := Assets.datos(nueva_clave)
		var celda: Array = datos_nuevo.get("celda_fisica", [128, 64])
		# Los atlas de suelo pueden contener variantes (agrietada, desgastada,
		# bronce), pero reemplazar un asset no debe heredar accidentalmente la
		# variante visual anterior. La variante automática oficial es la celda 0;
		# las demás sólo se usarán cuando exista una propiedad explícita por tile.
		var indice := 0
		var atlas_nuevo := AtlasTexture.new()
		atlas_nuevo.atlas = Assets.textura_celda(nueva_clave, indice, Vector2i(int(celda[0]), int(celda[1])))
		atlas_nuevo.region = Rect2(0.0, 0.0, float(celda[0]), float(celda[1]))
		sprite.texture = atlas_nuevo
	else:
		sprite.texture = Assets.textura(nueva_clave)
		sprite.centered = false
		sprite.offset = -Assets.pivote(nueva_clave)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_seleccionado.set_meta("layout_asset", nueva_clave)
	_actualizar_estado("Asset cambiado a: %s" % nueva_clave)

func _sprite_principal(nodo: Node) -> Sprite2D:
	if nodo is Sprite2D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _sprite_principal(hijo)
		if encontrado != null:
			return encontrado
	return null

func _calibracion_base_de_sprite(sprite: Sprite2D) -> Dictionary:
	return {
		"offset": sprite.offset,
		"escala": sprite.scale,
		"skew": sprite.skew,
		"rotacion": sprite.rotation,
	}

func _huella_de_nodo(nodo: Node2D) -> Vector2i:
	var huella: Variant = nodo.get_meta("layout_huella", Vector2i.ONE)
	if huella is Vector2i:
		return Vector2i(maxi(1, huella.x), maxi(1, huella.y))
	return Vector2i.ONE

func _actualizar_calibrador_desde_seleccion() -> void:
	if _calibrador == null or not is_instance_valid(_calibrador):
		return
	if _seleccionado == null or not is_instance_valid(_seleccionado):
		_calibrador.visible = false
		return
	var sprite := _sprite_principal(_seleccionado)
	if sprite == null:
		_calibrador.visible = false
		return
	var base: Dictionary = _seleccionado.get_meta("layout_calibracion_base", {})
	if base.is_empty():
		base = _calibracion_base_de_sprite(sprite)
		_seleccionado.set_meta("layout_calibracion_base", base)
	var base_offset: Vector2 = base.get("offset", sprite.offset)
	var base_escala: Vector2 = base.get("escala", sprite.scale)
	var base_skew: float = float(base.get("skew", sprite.skew))
	var base_rotacion: float = float(base.get("rotacion", sprite.rotation))
	_calibrador.global_position = _seleccionado.global_position
	_calibrador.configurar_con_base(sprite, _huella_de_nodo(_seleccionado), base_offset, base_escala, base_skew, base_rotacion)
	var ajustes: Dictionary = _seleccionado.get_meta("layout_calibracion", {})
	var offset: Array = ajustes.get("offset", [0.0, 0.0])
	var escala: Array = ajustes.get("escala", [1.0, 1.0])
	_calibrador.establecer_ajustes(
		Vector2(float(offset[0]), float(offset[1])) if offset.size() >= 2 else Vector2.ZERO,
		Vector2(float(escala[0]), float(escala[1])) if escala.size() >= 2 else Vector2.ONE,
		float(ajustes.get("skew", 0.0)),
		float(ajustes.get("rotacion", 0.0))
	)
	_aplicar_altura_muro(_seleccionado)
	_actualizar_controles_calibracion()

func _actualizar_controles_calibracion() -> void:
	if _cal_offset_x == null or _seleccionado == null:
		if _altura_muro_spin != null:
			_altura_muro_spin.visible = false
			_altura_muro_label.visible = false
		return
	var ajustes: Dictionary = _seleccionado.get_meta("layout_calibracion", {})
	var offset: Array = ajustes.get("offset", [0.0, 0.0])
	var escala: Array = ajustes.get("escala", [1.0, 1.0])
	_cal_offset_x.set_value_no_signal(float(offset[0]) if offset.size() >= 2 else 0.0)
	_cal_offset_y.set_value_no_signal(float(offset[1]) if offset.size() >= 2 else 0.0)
	_cal_escala_x.set_value_no_signal(float(escala[0]) if escala.size() >= 2 else 1.0)
	_cal_escala_y.set_value_no_signal(float(escala[1]) if escala.size() >= 2 else 1.0)
	_cal_skew.set_value_no_signal(float(ajustes.get("skew", 0.0)))
	_cal_rotacion.set_value_no_signal(float(ajustes.get("rotacion", 0.0)))
	if _altura_muro_spin != null:
		var es_muro := _es_muro_o_borde(_seleccionado)
		_altura_muro_spin.visible = es_muro
		_altura_muro_label.visible = es_muro
		if es_muro:
			_altura_muro_spin.set_value_no_signal(float(_altura_muro_de_nodo(_seleccionado)))

func _es_muro_o_borde(nodo: Node2D) -> bool:
	if nodo == null or not is_instance_valid(nodo):
		return false
	var rol := str(nodo.get_meta("layout_role", ""))
	return rol == "muro" or rol == "borde"

func _altura_muro_de_nodo(nodo: Node2D) -> int:
	if not _es_muro_o_borde(nodo):
		return 1
	return clampi(int(nodo.get_meta("layout_altura_muro", 1)), 1, 4)

func _cambiar_altura_muro(valor: float) -> void:
	if _seleccionado == null or not _es_muro_o_borde(_seleccionado):
		return
	var niveles := clampi(roundi(valor), 1, 4)
	if niveles == _altura_muro_de_nodo(_seleccionado):
		return
	_guardar_historial()
	_seleccionado.set_meta("layout_altura_muro", niveles)
	_aplicar_calibracion_a_nodo(_seleccionado, _seleccionado.get_meta("layout_calibracion", {}))
	_actualizar_estado("Altura visual del muro: %d nivel%s" % [niveles, "" if niveles == 1 else "es"])
	_actualizar_panel()
	queue_redraw()

func _cambiar_calibracion(_valor: float) -> void:
	if _calibrador == null or _seleccionado == null or not is_instance_valid(_seleccionado):
		return
	_calibrador.establecer_ajustes(
		Vector2(_cal_offset_x.value, _cal_offset_y.value),
		Vector2(_cal_escala_x.value, _cal_escala_y.value),
		_cal_skew.value,
		_cal_rotacion.value
	)
	_seleccionado.set_meta("layout_calibracion", _calibrador.estado())
	_aplicar_altura_muro(_seleccionado)
	_actualizar_estado("Calibracion visual aplicada solo al sprite")
	_guardar_historial()
	queue_redraw()

func _alternar_guia_calibracion() -> void:
	if _calibrador == null or _seleccionado == null:
		_actualizar_estado("Selecciona un objeto con Sprite2D")
		return
	_calibrador.visible = not _calibrador.visible
	_actualizar_estado("Guia isometrica %s" % ("visible" if _calibrador.visible else "oculta"))
	queue_redraw()

func _restaurar_calibracion_seleccionada() -> void:
	if _calibrador == null or _seleccionado == null:
		return
	_guardar_historial()
	_calibrador.restaurar()
	_seleccionado.set_meta("layout_calibracion", _calibrador.estado())
	_aplicar_altura_muro(_seleccionado)
	_actualizar_controles_calibracion()
	_actualizar_estado("Calibracion visual restaurada")
	queue_redraw()

func _aplicar_calibracion_a_nodo(nodo: Node2D, ajustes: Dictionary) -> void:
	var sprite := _sprite_principal(nodo)
	if sprite == null:
		return
	var base: Dictionary = nodo.get_meta("layout_calibracion_base", {})
	if base.is_empty():
		base = _calibracion_base_de_sprite(sprite)
		nodo.set_meta("layout_calibracion_base", base)
	var offset: Array = ajustes.get("offset", [0.0, 0.0])
	var escala: Array = ajustes.get("escala", [1.0, 1.0])
	sprite.offset = base.get("offset", sprite.offset) + (Vector2(float(offset[0]), float(offset[1])) if offset.size() >= 2 else Vector2.ZERO)
	var escala_base: Vector2 = base.get("escala", sprite.scale)
	var escala_ajuste := Vector2(float(escala[0]), float(escala[1])) if escala.size() >= 2 else Vector2.ONE
	sprite.scale = Vector2(escala_base.x * escala_ajuste.x, escala_base.y * escala_ajuste.y)
	sprite.skew = float(base.get("skew", sprite.skew)) + deg_to_rad(float(ajustes.get("skew", 0.0)))
	sprite.rotation = float(base.get("rotacion", sprite.rotation)) + deg_to_rad(float(ajustes.get("rotacion", 0.0)))
	nodo.set_meta("layout_calibracion", ajustes)
	_aplicar_altura_muro(nodo)

func _aplicar_altura_muro(nodo: Node2D) -> void:
	if not _es_muro_o_borde(nodo):
		return
	var sprite := _sprite_principal(nodo)
	if sprite == null or sprite.texture == null:
		return
	var base: Dictionary = nodo.get_meta("layout_altura_base", {})
	if base.is_empty():
		var base_calibracion: Dictionary = nodo.get_meta("layout_calibracion_base", {})
		base = {
			"escala": base_calibracion.get("escala", sprite.scale),
			"posicion": sprite.position,
			"offset": base_calibracion.get("offset", sprite.offset),
		}
		nodo.set_meta("layout_altura_base", base)
	var calibracion: Dictionary = nodo.get_meta("layout_calibracion", {})
	var offset_crudo: Array = calibracion.get("offset", [0.0, 0.0])
	var escala_cruda: Array = calibracion.get("escala", [1.0, 1.0])
	var base_offset: Vector2 = base.get("offset", sprite.offset)
	var base_escala: Vector2 = base.get("escala", sprite.scale)
	var base_posicion: Vector2 = base.get("posicion", sprite.position)
	var ajuste_offset := Vector2(float(offset_crudo[0]), float(offset_crudo[1])) if offset_crudo.size() >= 2 else Vector2.ZERO
	var ajuste_escala := Vector2(float(escala_cruda[0]), float(escala_cruda[1])) if escala_cruda.size() >= 2 else Vector2.ONE
	var niveles := float(_altura_muro_de_nodo(nodo))
	var offset_final := base_offset + ajuste_offset
	var escala_sin_altura := Vector2(base_escala.x * ajuste_escala.x, base_escala.y * ajuste_escala.y)
	var escala_final := Vector2(escala_sin_altura.x, escala_sin_altura.y * niveles)
	var altura_textura := float(sprite.texture.get_height())
	var base_inferior := base_posicion.y + base_escala.y * (base_offset.y + altura_textura)
	sprite.offset = offset_final
	sprite.scale = escala_final
	sprite.position = base_posicion
	sprite.position.y = base_inferior - escala_final.y * (offset_final.y + altura_textura)

func _ocultar_seleccionado() -> void:
	if _seleccionados.is_empty() and _seleccionado != null:
		_seleccionados = [_seleccionado]
	if _seleccionados.is_empty():
		return
	_guardar_historial()
	var ocultar := false
	for nodo in _seleccionados:
		if nodo != null and is_instance_valid(nodo) and _es_editable_en_modo(nodo):
			ocultar = not nodo.visible
			break
	for nodo in _seleccionados:
		if nodo != null and is_instance_valid(nodo) and _es_editable_en_modo(nodo):
			nodo.visible = ocultar
			nodo.set_meta("layout_oculto_por_boton", not ocultar)
			nodo.process_mode = Node.PROCESS_MODE_INHERIT if ocultar else Node.PROCESS_MODE_DISABLED
	_actualizar_estado("%s %d objetos" % ["Restaurados" if ocultar else "Ocultados", _seleccionados.size()])

func _quitar_transicion_seleccionada() -> void:
	if _seleccionado == null or not is_instance_valid(_seleccionado):
		return
	if str(_seleccionado.get_meta("layout_role", "")) != "transicion":
		_actualizar_estado("Selecciona primero una puerta o escalera")
		return
	_guardar_historial()
	var cantidad := 0
	for nodo in _seleccionados:
		if nodo != null and is_instance_valid(nodo) and str(nodo.get_meta("layout_role", "")) == "transicion":
			nodo.visible = false
			nodo.process_mode = Node.PROCESS_MODE_DISABLED
			nodo.set_meta("layout_oculto_por_boton", true)
			cantidad += 1
	_actualizar_estado("Quitadas %d transiciones. Ctrl+Z las restaura; Ctrl+S guarda el cambio." % cantidad)
	_actualizar_panel()
	queue_redraw()

func _cancelar_arrastre() -> void:
	_arrastrando = false

func _seleccion_anterior() -> void:
	_cambiar_seleccion(-1)

func _seleccion_siguiente() -> void:
	_cambiar_seleccion(1)

func _cambiar_seleccion(direccion: int) -> void:
	if _orden_ids.is_empty():
		return
	var actual := _orden_ids.find(str(_seleccionado.get_meta("layout_id", ""))) if _seleccionado != null else -1
	actual = posmod(actual + direccion, _orden_ids.size())
	_seleccionado = _elementos[_orden_ids[actual]]
	_seleccionados = [_seleccionado]
	_actualizar_calibrador_desde_seleccion()
	_actualizar_estado("Seleccionado: %s" % _orden_ids[actual])

func _cambiar_offset_x(valor: float) -> void:
	_cambiar_offset(Vector2(valor, _offset_actual().y))

func _cambiar_offset_y(valor: float) -> void:
	_cambiar_offset(Vector2(_offset_actual().x, valor))

func _cambiar_offset(offset: Vector2) -> void:
	if _seleccionado == null:
		return
	var base: Vector2 = _seleccionado.get_meta("layout_base_position", _seleccionado.position)
	_seleccionado.position = base + offset
	_actualizar_panel()
	queue_redraw()

func _offset_actual() -> Vector2:
	if _seleccionado == null:
		return Vector2.ZERO
	var base: Vector2 = _seleccionado.get_meta("layout_base_position", _seleccionado.position)
	return _seleccionado.position - base

func _actualizar_panel() -> void:
	if _elemento == null:
		return
	if _tamano_editor_label != null:
		_tamano_editor_label.text = "Sala: %d × %d casillas (solo editor)" % [_ancho_editor, _alto_editor]
	if _seleccionado == null:
		_elemento.text = "Elemento: ninguno"
		_rotacion.text = "Rotacion: --"
		_actualizar_controles_calibracion()
		_actualizar_editor_transicion(null)
		_zoom_sala_label.text = "Sala: %d%%" % round(_zoom_sala * 100.0)
		_zoom_referencia_label.text = "Referencia: %d%%" % round(_zoom_referencia * 100.0)
		return
	var id := str(_seleccionado.get_meta("layout_id", "?"))
	var rol := str(_seleccionado.get_meta("layout_role", "?"))
	var asset := str(_seleccionado.get_meta("layout_asset", ""))
	var offset := _offset_actual()
	_elemento.text = "Elemento: %s\nRol: %s\nAsset: %s\nPosicion: %d, %d" % [id, rol, asset, round(_seleccionado.global_position.x), round(_seleccionado.global_position.y)]
	_offset_x.set_value_no_signal(offset.x)
	_offset_y.set_value_no_signal(offset.y)
	_rotacion.text = "Offset: %d, %d    Rotacion: %d grados" % [round(offset.x), round(offset.y), round(rad_to_deg(_seleccionado.rotation))]
	_actualizar_controles_calibracion()
	_actualizar_editor_transicion(_seleccionado)
	_zoom_sala_label.text = "Sala: %d%%" % round(_zoom_sala * 100.0)
	_zoom_referencia_label.text = "Referencia: %d%%" % round(_zoom_referencia * 100.0)

func _actualizar_editor_transicion(nodo: Node2D) -> void:
	var es_transicion := nodo != null and is_instance_valid(nodo) and str(nodo.get_meta("layout_role", "")) == "transicion"
	if _transicion_info != null:
		_transicion_info.visible = es_transicion
	if _destino_zona_edit != null:
		_destino_zona_edit.editable = es_transicion
		_destino_zona_edit.visible = es_transicion
	if _entrada_destino_x != null:
		_entrada_destino_x.editable = es_transicion
		_entrada_destino_x.visible = es_transicion
	if _entrada_destino_y != null:
		_entrada_destino_y.editable = es_transicion
		_entrada_destino_y.visible = es_transicion
	if _accion_transicion_edit != null:
		_accion_transicion_edit.editable = es_transicion
		_accion_transicion_edit.visible = es_transicion
	if _boton_quitar_transicion != null:
		_boton_quitar_transicion.visible = es_transicion
	if not es_transicion:
		return
	var entrada: Vector2i = nodo.get_meta("layout_entrada_destino", Vector2i.ONE)
	_destino_zona_edit.set_text(str(nodo.get_meta("layout_destino_zona", "")))
	_entrada_destino_x.set_value_no_signal(entrada.x)
	_entrada_destino_y.set_value_no_signal(entrada.y)
	_accion_transicion_edit.set_text(str(nodo.get_meta("layout_accion", "Usar")))
	_transicion_info.text = "TRANSICION · mueve el cuadrado, destino y entrada editables"

func _aplicar_datos_transicion(_texto: String = "") -> void:
	if _seleccionado == null or str(_seleccionado.get_meta("layout_role", "")) != "transicion":
		return
	_guardar_historial()
	var destino := _destino_zona_edit.text.strip_edges()
	_seleccionado.set_meta("layout_destino_zona", destino)
	_seleccionado.set_meta("layout_entrada_destino", Vector2i(int(_entrada_destino_x.value), int(_entrada_destino_y.value)))
	_seleccionado.set_meta("layout_accion", _accion_transicion_edit.text.strip_edges())
	if _seleccionado is TransicionZona:
		var t := _seleccionado as TransicionZona
		t.destino_zona = destino
		t.entrada_destino = Vector2i(int(_entrada_destino_x.value), int(_entrada_destino_y.value))
		t.accion = _accion_transicion_edit.text.strip_edges()
	_actualizar_estado("Datos de transición actualizados")

func _aplicar_datos_transicion_valor(_valor: float) -> void:
	_aplicar_datos_transicion()

func _alternar_vista_limpia() -> void:
	_vista_limpia = not _vista_limpia
	_panel.visible = not _vista_limpia
	_panel_comandos.visible = not _vista_limpia
	if _boton_panel != null:
		_boton_panel.visible = not _vista_limpia
	if _boton_comandos != null:
		_boton_comandos.visible = not _vista_limpia
	if _boton_paleta != null:
		_boton_paleta.visible = not _vista_limpia
	if _boton_mover_paleta != null:
		_boton_mover_paleta.visible = not _vista_limpia and _paleta_expandida
	if _boton_mover_panel != null:
		_boton_mover_panel.visible = not _vista_limpia and _panel_expandido
	if _boton_mover_comandos != null:
		_boton_mover_comandos.visible = not _vista_limpia and _comandos_expandidos
	if _boton_mover_referencia != null:
		_boton_mover_referencia.visible = not _vista_limpia and _referencia_visible
	if _paleta != null:
		_paleta.visible = not _vista_limpia and _paleta_expandida
	if get_parent() != null:
		for hijo in get_parent().get_children():
			if hijo is Label and hijo != _estado:
				hijo.visible = not _vista_limpia
	_actualizar_estado("Vista limpia activa" if _vista_limpia else "Editor visual activo")
	_actualizar_manejadores_ui()

func _capturar_layout() -> Dictionary:
	var lista: Array = []
	for id in _orden_ids:
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo):
			continue
		var base: Vector2 = nodo.get_meta("layout_base_position", nodo.position)
		var casilla: Vector2i = nodo.get_meta("layout_casilla", Vector2i.ZERO)
		var offset := nodo.position - base
		lista.append({
			"id": id,
			"rol": str(nodo.get_meta("layout_role", "")),
			"asset": str(nodo.get_meta("layout_asset", "")),
			"casilla": [casilla.x, casilla.y],
			"wall_axis": str(nodo.get_meta("layout_wall_axis", "")),
			"huella": _serializar_vector2i(nodo.get_meta("layout_huella", Vector2i.ONE)),
			"solido": bool(nodo.get_meta("layout_solido", false)),
			"offset_px": [round(offset.x), round(offset.y)],
			"calibracion": nodo.get_meta("layout_calibracion", {}),
			"altura_muro": _altura_muro_de_nodo(nodo),
			"rotacion": 0.0,
			"espejo_x": nodo.scale.x < 0.0,
		"espejo_y": nodo.scale.y < 0.0,
			"transicion_tipo": str(nodo.get_meta("layout_transition_type", "")),
			"destino_zona": str(nodo.get_meta("layout_destino_zona", "")),
			"entrada_destino": _serializar_vector2i(nodo.get_meta("layout_entrada_destino", Vector2i.ONE)),
			"accion": str(nodo.get_meta("layout_accion", "Usar")),
			"visible": nodo.visible,
		})
	return {"version": 2, "interior_id": interior.definicion.id if interior != null and interior.definicion != null else "", "tamano": [_ancho_editor, _alto_editor], "elementos": lista}

func _registrar_id_asset_editor(id: String) -> void:
	if not id.begins_with("asset_editor_"):
		return
	var sufijo := id.trim_prefix("asset_editor_")
	if sufijo.is_valid_int():
		_siguiente_asset_id = maxi(_siguiente_asset_id, int(sufijo) + 1)

func _crear_nodo_faltante_desde_layout(entrada: Dictionary) -> Node2D:
	if interior == null:
		return null
	var id := str(entrada.get("id", "")).strip_edges()
	var rol := str(entrada.get("rol", "")).strip_edges()
	var clave := str(entrada.get("asset", "")).strip_edges()
	if id == "" or rol == "" or clave == "" or not Assets.existe(clave):
		return null
	if _elementos.has(id):
		return _elementos.get(id) as Node2D

	var casilla := _deserializar_vector2i(entrada.get("casilla", [0, 0]))
	var huella := _deserializar_vector2i(entrada.get("huella", [1, 1]))
	huella = Vector2i(maxi(1, huella.x), maxi(1, huella.y))
	var nodo: Node2D = TransicionZonaScript.new() if rol == "transicion" else Node2D.new()
	nodo.name = id
	nodo.position = _posicion_muro_local(casilla, clave) if rol in ["muro", "borde"] else Iso.centro_v(casilla)
	nodo.set_meta("layout_id", id)
	nodo.set_meta("layout_role", rol)
	nodo.set_meta("layout_asset", clave)
	nodo.set_meta("layout_casilla", casilla)
	nodo.set_meta("layout_huella", huella)
	nodo.set_meta("layout_solido", bool(entrada.get("solido", rol == "mueble")))
	nodo.set_meta("layout_base_position", nodo.position)
	if rol in ["muro", "borde"]:
		nodo.set_meta("layout_wall_axis", str(entrada.get("wall_axis", _eje_muro(clave, casilla))))
	nodo.set_meta("layout_base_rotation", 0.0)
	nodo.set_meta("layout_transition_type", str(entrada.get("transicion_tipo", "")))
	nodo.set_meta("layout_destino_zona", str(entrada.get("destino_zona", "")))
	nodo.set_meta("layout_entrada_destino", _deserializar_vector2i(entrada.get("entrada_destino", [1, 1])))
	nodo.set_meta("layout_accion", str(entrada.get("accion", "Usar")))
	nodo.set_meta("layout_altura_muro", clampi(int(entrada.get("altura_muro", 1)), 1, 4))

	if rol == "suelo":
		nodo.add_child(_crear_sprite_suelo(clave, casilla))
	else:
		nodo.add_child(_crear_sprite_asset(clave))

	var contenedor: Node = interior
	if rol == "suelo" or rol == "muro" or rol == "borde":
		var arte_base := interior.get_node_or_null("ArteBase") as Node
		if arte_base != null:
			contenedor = arte_base
	contenedor.add_child(nodo)
	if rol == "suelo":
		contenedor.move_child(nodo, 0)

	if nodo is TransicionZona:
		var transicion := nodo as TransicionZona
		transicion.casilla_propia = casilla
		transicion.destino_zona = str(entrada.get("destino_zona", ""))
		transicion.entrada_destino = _deserializar_vector2i(entrada.get("entrada_destino", [1, 1]))
		transicion.accion = str(entrada.get("accion", "Usar"))
		transicion.establecer_casillas_interaccion(_casillas_de_acceso_editor(casilla))
		if interior.has_method("registrar_transicion_editor"):
			interior.registrar_transicion_editor(transicion)

	_elementos[id] = nodo
	_orden_ids.append(id)
	_orden_ids.sort()
	_registrar_id_asset_editor(id)
	return nodo

func _aplicar_asset(nodo: Node2D, nueva_clave: String) -> void:
	if nueva_clave == "" or not Assets.existe(nueva_clave):
		return
	var rol := str(nodo.get_meta("layout_role", ""))
	var sprite := _sprite_principal(nodo)
	if sprite == null:
		return
	if rol == "suelo":
		var atlas_actual := sprite.texture as AtlasTexture
		var nueva_textura := Assets.textura(nueva_clave)
		var datos_nuevo := Assets.datos(nueva_clave)
		var celda: Array = datos_nuevo.get("celda_fisica", [128, 64])
		var indice := 0
		if atlas_actual != null and atlas_actual.atlas != null:
			var ancho_celda := maxf(1.0, float(celda[0]))
			indice = int(round(atlas_actual.region.position.x / ancho_celda))
			indice = clampi(indice, 0, maxi(0, int(nueva_textura.get_width() / ancho_celda) - 1))
		var atlas_nuevo := AtlasTexture.new()
		atlas_nuevo.atlas = Assets.textura_celda(nueva_clave, indice, Vector2i(int(celda[0]), int(celda[1])))
		atlas_nuevo.region = Rect2(0.0, 0.0, float(celda[0]), float(celda[1]))
		sprite.texture = atlas_nuevo
	else:
		sprite.texture = Assets.textura(nueva_clave)
		sprite.centered = false
	sprite.offset = -Assets.pivote(nueva_clave)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	nodo.set_meta("layout_calibracion_base", _calibracion_base_de_sprite(sprite))
	nodo.set_meta("layout_calibracion", {})
	if _es_muro_o_borde(nodo):
		nodo.set_meta("layout_altura_muro", 1)
		nodo.set_meta("layout_altura_base", {})
		nodo.set_meta("layout_wall_axis", _eje_muro(nueva_clave, nodo.get_meta("layout_casilla", Vector2i.ZERO)))
	nodo.set_meta("layout_asset", nueva_clave)

func _aplicar_layout(datos: Dictionary) -> void:
	var tamano: Variant = datos.get("tamano", [])
	if tamano is Array and tamano.size() >= 2:
		_ancho_editor = maxi(TAMANO_MINIMO, int(tamano[0]))
		_alto_editor = maxi(TAMANO_MINIMO, int(tamano[1]))
		_aplicar_tamano_visual()
	var lista: Array = datos.get("elementos", [])
	for crudo in lista:
		var entrada: Dictionary = crudo
		var nodo: Node2D = _elementos.get(str(entrada.get("id", "")))
		if nodo == null:
			nodo = _crear_nodo_faltante_desde_layout(entrada)
		if nodo == null:
			continue
		_aplicar_asset(nodo, str(entrada.get("asset", "")))
		if _es_muro_o_borde(nodo):
			nodo.set_meta("layout_altura_muro", clampi(int(entrada.get("altura_muro", 1)), 1, 4))
		_aplicar_calibracion_a_nodo(nodo, entrada.get("calibracion", {}))
		var destino := str(entrada.get("destino_zona", nodo.get_meta("layout_destino_zona", "")))
		var entrada_destino := _deserializar_vector2i(entrada.get("entrada_destino", [1, 1]))
		var casilla_guardada := _deserializar_vector2i(entrada.get("casilla", _serializar_vector2i(nodo.get_meta("layout_casilla", Vector2i.ZERO))))
		var rol := str(nodo.get_meta("layout_role", ""))
		nodo.set_meta("layout_casilla", casilla_guardada)
		if rol in ["muro", "borde"]:
			nodo.set_meta("layout_wall_axis", str(entrada.get("wall_axis", _eje_muro(str(entrada.get("asset", nodo.get_meta("layout_asset", ""))), casilla_guardada))))
			nodo.set_meta("layout_base_position", _posicion_muro_local(casilla_guardada, str(nodo.get_meta("layout_asset", ""))))
		nodo.set_meta("layout_destino_zona", destino)
		nodo.set_meta("layout_entrada_destino", entrada_destino)
		nodo.set_meta("layout_accion", str(entrada.get("accion", nodo.get_meta("layout_accion", "Usar"))))
		if nodo is TransicionZona:
			var transicion := nodo as TransicionZona
			transicion.destino_zona = destino
			transicion.entrada_destino = entrada_destino
			transicion.accion = str(nodo.get_meta("layout_accion", "Usar"))
		elif nodo is Puerta:
			(nodo as Puerta).casilla_propia = casilla_guardada
		if nodo is TransicionZona:
			(nodo as TransicionZona).casilla_propia = casilla_guardada
			(nodo as TransicionZona).establecer_casillas_interaccion(_casillas_de_acceso_editor(casilla_guardada))
		var base: Vector2 = nodo.get_meta("layout_base_position", nodo.position)
		var o: Array = entrada.get("offset_px", [0, 0])
		if rol == "transicion":
			nodo.position = Iso.centro_v(casilla_guardada)
		elif o.size() >= 2:
			nodo.position = base + Vector2(float(o[0]), float(o[1]))
		nodo.rotation = 0.0
		var escala_x := -1.0 if bool(entrada.get("espejo_x", false)) else 1.0
		var escala_y := -1.0 if bool(entrada.get("espejo_y", false)) else 1.0
		nodo.scale = Vector2(escala_x, escala_y)
		nodo.visible = bool(entrada.get("visible", true))
		nodo.set_meta("layout_oculto_por_boton", not nodo.visible)
		nodo.process_mode = Node.PROCESS_MODE_INHERIT if nodo.visible else Node.PROCESS_MODE_DISABLED
	# Recalcula la transitabilidad con los nodos que el layout haya creado.
	# Restauramos después la visibilidad exacta del archivo para no reactivar
	# capas que el usuario había ocultado deliberadamente.
	_aplicar_tamano_visual()
	for crudo in lista:
		var entrada_visible: Dictionary = crudo
		var nodo_visible: Node2D = _elementos.get(str(entrada_visible.get("id", "")))
		if nodo_visible == null or not is_instance_valid(nodo_visible):
			continue
		nodo_visible.visible = bool(entrada_visible.get("visible", true))
		nodo_visible.set_meta("layout_oculto_por_boton", not nodo_visible.visible)
		nodo_visible.process_mode = Node.PROCESS_MODE_INHERIT if nodo_visible.visible else Node.PROCESS_MODE_DISABLED
	_actualizar_visibilidad_capas()
	queue_redraw()
	_actualizar_estado("Layout cargado")

func _serializar_vector2i(valor: Variant) -> Array:
	var v: Vector2i = valor if valor is Vector2i else Vector2i.ONE
	return [v.x, v.y]

func _deserializar_vector2i(valor: Variant) -> Vector2i:
	if valor is Array and valor.size() >= 2:
		return Vector2i(int(valor[0]), int(valor[1]))
	return Vector2i.ONE

func _guardar_layout() -> void:
	var ruta_absoluta := ProjectSettings.globalize_path(RUTA_LAYOUT)
	DirAccess.make_dir_recursive_absolute(ruta_absoluta.get_base_dir())
	# Cada guardado conserva la versión anterior. Así una prueba de edición
	# nunca obliga a reconstruir manualmente una sala que se haya estropeado.
	if FileAccess.file_exists(RUTA_LAYOUT):
		var respaldo_absoluto := ProjectSettings.globalize_path(RUTA_LAYOUT_RESPALDO)
		DirAccess.copy_absolute(ruta_absoluta, respaldo_absoluto)
	var archivo := FileAccess.open(RUTA_LAYOUT, FileAccess.WRITE)
	if archivo == null:
		_actualizar_estado("ERROR: no se pudo guardar el layout")
		return
	archivo.store_string(JSON.stringify(_capturar_layout(), "\t"))
	archivo.close()
	_actualizar_estado("Layout guardado: %s" % RUTA_LAYOUT)

func _guardar_respaldo_automatico(motivo: String) -> void:
	if interior == null or not is_instance_valid(interior):
		return
	var ruta_absoluta := ProjectSettings.globalize_path(RUTA_LAYOUT_AUTOSALVADO)
	DirAccess.make_dir_recursive_absolute(ruta_absoluta.get_base_dir())
	var archivo := FileAccess.open(RUTA_LAYOUT_AUTOSALVADO, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo crear autosalvado del editor: %s" % motivo)
		return
	var datos := _capturar_layout()
	datos["tipo"] = "autosave_editor"
	datos["motivo"] = motivo
	datos["timestamp"] = Time.get_datetime_string_from_system()
	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.close()

func _recuperar_respaldo() -> void:
	if not FileAccess.file_exists(RUTA_LAYOUT_RESPALDO):
		_actualizar_estado("No existe un respaldo .bak todavía")
		return
	var origen := ProjectSettings.globalize_path(RUTA_LAYOUT_RESPALDO)
	var destino := ProjectSettings.globalize_path(RUTA_LAYOUT)
	var error := DirAccess.copy_absolute(origen, destino)
	if error != OK:
		_actualizar_estado("ERROR: no se pudo recuperar el respaldo")
		return
	_cargar_layout(true)
	_guardar_historial()
	_actualizar_estado("Respaldo recuperado. El layout anterior está restaurado")

func _nombre_plantilla_actual() -> String:
	if interior != null and interior.definicion != null and not interior.definicion.id.is_empty():
		return interior.definicion.id
	return _plantilla_nombre

func _guardar_plantilla() -> void:
	var nombre := _nombre_plantilla_actual()
	var datos := _capturar_layout()
	datos["tipo"] = "plantilla_interior"
	datos["nombre"] = nombre
	if InteriorTemplateManagerScript.guardar(nombre, datos):
		_actualizar_estado("Plantilla guardada: %s" % nombre)
	else:
		_actualizar_estado("ERROR: no se pudo guardar la plantilla")

func _cargar_plantilla() -> void:
	var nombre := _nombre_plantilla_actual()
	var datos := InteriorTemplateManagerScript.cargar(nombre)
	if datos.is_empty():
		_actualizar_estado("No existe plantilla para %s" % nombre)
		return
	_guardar_respaldo_automatico("carga de plantilla")
	_guardar_historial()
	_aplicar_layout(datos)
	_guardar_historial()
	_actualizar_estado("Plantilla cargada: %s" % nombre)
	queue_redraw()

func _cargar_layout(mostrar: bool) -> void:
	if not FileAccess.file_exists(RUTA_LAYOUT):
		if mostrar:
			_actualizar_estado("No existe layout guardado; se usa la definicion base")
		return
	var archivo := FileAccess.open(RUTA_LAYOUT, FileAccess.READ)
	if archivo == null:
		_actualizar_estado("ERROR: no se pudo abrir el layout")
		return
	var datos: Variant = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if typeof(datos) != TYPE_DICTIONARY:
		_actualizar_estado("ERROR: JSON de layout invalido")
		return
	_guardar_respaldo_automatico("carga de layout")
	_guardar_historial()
	_aplicar_layout(datos)

func _guardar_historial() -> void:
	var estado := _capturar_layout()
	if _historial_indice >= 0 and _historial_indice < _historial.size() - 1:
		_historial = _historial.slice(0, _historial_indice + 1)
	_historial.append(estado)
	if _historial.size() > 40:
		_historial.pop_front()
	_historial_indice = _historial.size() - 1

func _deshacer() -> void:
	if _historial_indice <= 0:
		return
	_historial_indice -= 1
	_aplicar_layout(_historial[_historial_indice])
	_actualizar_estado("Deshacer")

func _rehacer() -> void:
	if _historial_indice >= _historial.size() - 1:
		return
	_historial_indice += 1
	_aplicar_layout(_historial[_historial_indice])
	_actualizar_estado("Rehacer")

func _actualizar_estado(texto: String) -> void:
	if _estado != null:
		_estado.text = texto

func _draw() -> void:
	if interior == null or interior.definicion == null:
		return
	if _mostrar_rejilla or _mostrar_transitable:
		for y in _alto_editor:
			for x in _ancho_editor:
				var centro := interior.to_global(Iso.centro(x, y))
				var puntos := PackedVector2Array([
					centro + Vector2(0, -Iso.MEDIO_Y),
					centro + Vector2(Iso.MEDIO_X, 0),
					centro + Vector2(0, Iso.MEDIO_Y),
					centro + Vector2(-Iso.MEDIO_X, 0),
				])
				if _mostrar_transitable:
					var libre := true
					if interior.transitable != null and interior.transitable.has_method("puede_pisar"):
						libre = bool(interior.transitable.call("puede_pisar", Vector2i(x, y)))
						draw_colored_polygon(puntos, COLOR_TRANSITABLE_EDITOR if libre else COLOR_BLOQUEADO_EDITOR)
				if _mostrar_rejilla:
					draw_polyline(PackedVector2Array([puntos[0], puntos[1], puntos[2], puntos[3], puntos[0]]), COLOR_REJILLA_EDITOR, 1.0)
				if _mostrar_subrejilla:
					_dibujar_subrejilla_tile(centro)
	if _mostrar_rejilla_muros:
		_dibujar_rejilla_muros()
	if _base_oculta_por_boton:
		_dibujar_lienzo_base_vacio()
	if _mostrar_colisiones:
		for m in interior.definicion.muebles:
			var mueble: Dictionary = m
			if not bool(mueble.get("solido", true)):
				continue
			var origen: Variant = mueble.get("casilla", Vector2i.ZERO)
			var huella: Variant = mueble.get("huella", Vector2i.ONE)
			if not origen is Vector2i or not huella is Vector2i:
				continue
			var o: Vector2i = origen
			var h: Vector2i = huella
			var centro := interior.to_global(Iso.centro(o.x, o.y))
			var fin := interior.to_global(Iso.centro(o.x + h.x - 1, o.y + h.y - 1))
			var recto := Rect2(minf(centro.x, fin.x) - Iso.MEDIO_X * 0.5,
				minf(centro.y, fin.y) - Iso.MEDIO_Y * 0.5,
				absf(fin.x - centro.x) + Iso.MEDIO_X,
				absf(fin.y - centro.y) + Iso.MEDIO_Y)
			draw_rect(recto, Color(0.90, 0.25, 0.22, 0.65), false, 2.0)
	if _mostrar_capas and _seleccionado != null:
		var rol := str(_seleccionado.get_meta("layout_role", "?"))
		draw_string(ThemeDB.fallback_font, _seleccionado.global_position + Vector2(10, -10), rol,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GlobalColors.get_color_seleccion())
	if _mostrar_guias and _seleccionado != null and is_instance_valid(_seleccionado):
		var punto := _seleccionado.global_position
		draw_circle(punto, 5.0, GlobalColors.get_color_interaccion())
		draw_line(punto - Vector2(12, 0), punto + Vector2(12, 0), GlobalColors.get_color_seleccion(), 1.0)
		draw_line(punto - Vector2(0, 12), punto + Vector2(0, 12), GlobalColors.get_color_seleccion(), 1.0)
	if _seleccionando_marco:
		var marco_global := Rect2(_marco_inicio, _marco_actual - _marco_inicio).abs()
		var marco_local := Rect2(to_local(marco_global.position), marco_global.size)
		draw_rect(marco_local, Color(0.30, 0.85, 0.50, 0.12), true)
		draw_rect(marco_local, Color("#4a804d"), false, 2.0)
	if _seleccionando_region_colocacion:
		var region_global := Rect2(_region_colocacion_inicio, _region_colocacion_actual - _region_colocacion_inicio).abs()
		var region_local := Rect2(to_local(region_global.position), region_global.size)
		draw_rect(region_local, Color(0.96, 0.75, 0.25, 0.12), true)
		draw_rect(region_local, GlobalColors.get_color_interaccion(), false, 2.0)
	if _seleccionando_relleno_muro:
		_dibujar_preview_perimetro_muro()
	_dibujar_resaltado(_hovered, Color("#4a804d"))
	for nodo in _seleccionados:
		if nodo != _hovered:
			_dibujar_resaltado(nodo, GlobalColors.get_color_interaccion())
	if _seleccionados.is_empty():
		_dibujar_resaltado(_seleccionado, GlobalColors.get_color_interaccion())
	if _seleccionado != null and is_instance_valid(_seleccionado):
		_dibujar_gizmo(_seleccionado)
	if _hovered != null and is_instance_valid(_hovered):
		_dibujar_nombre_hover(_hovered)
	elif _hover_muro_eje != "":
		var estado_muro := "Muro ocupado" if _buscar_muro_en_celda(_hover_muro_casilla, _hover_muro_eje) != null else "Celda de muro vacia"
		var punto_muro := _puntos_celda_muro_global(_hover_muro_casilla, _hover_muro_eje)[0]
		draw_string(ThemeDB.fallback_font, punto_muro + Vector2(8, -8), estado_muro,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, GlobalColors.get_color_interaccion())
	_dibujar_diagnosticos()

func _dibujar_preview_perimetro_muro() -> void:
	if interior == null:
		return
	var inicio := Iso.a_tile(interior.to_local(_relleno_muro_inicio))
	var fin := Iso.a_tile(interior.to_local(_relleno_muro_actual))
	var min_x := mini(inicio.x, fin.x)
	var max_x := maxi(inicio.x, fin.x)
	var min_y := mini(inicio.y, fin.y)
	var max_y := maxi(inicio.y, fin.y)
	var color := GlobalColors.get_color_interaccion()
	for x in range(min_x, max_x + 1):
		_dibujar_arista_muro(Vector2i(x, min_y), "x", color)
		_dibujar_arista_muro(Vector2i(x, max_y), "x", color)
	for y in range(min_y + 1, max_y):
		_dibujar_arista_muro(Vector2i(min_x, y), "y", color)
		_dibujar_arista_muro(Vector2i(max_x, y), "y", color)
	var centro := interior.to_global(Iso.centro(min_x, min_y))
	draw_string(ThemeDB.fallback_font, centro + Vector2(-30, -42), "PERIMETRO DE MURO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)

func _dibujar_rejilla_muros() -> void:
	if interior == null:
		return
	# La rejilla mural usa el mismo gris neutro del lienzo, no verde.
	# Verde queda reservado para el hover temporal de edición.
	var color_rejilla := Color("#8b8b9e", 0.94)
	_dibujar_lienzo_muros_vacio()
	# La rejilla de muros no debe repetir la rejilla del suelo. Solo muestra
	# los anclajes de los dos perímetros donde nacen las paredes de fondo:
	# fila y=0 hacia +X y columna x=0 hacia +Y.
	_dibujar_arista_muro(Vector2i.ZERO, "esquina", color_rejilla)
	for x in range(1, _ancho_editor):
		_dibujar_arista_muro(Vector2i(x, 0), "x", color_rejilla)
	for y in range(1, _alto_editor):
		_dibujar_arista_muro(Vector2i(0, y), "y", color_rejilla)

	var esquina := _posicion_muro_global(Vector2i(0, 0), "")
	var extremo_x := _posicion_muro_global(Vector2i(_ancho_editor, 0), "")
	var extremo_y := _posicion_muro_global(Vector2i(0, _alto_editor), "")
	var altura := Vector2(0.0, -ALTURA_REJILLA_MURO_FISICA)
	var a := to_local(esquina)
	var bx := to_local(extremo_x)
	var by := to_local(extremo_y)
	var at := a + altura
	var bxt := bx + altura
	var byt := by + altura
	draw_line(a, bx, color_rejilla, 3.0)
	draw_line(a, by, color_rejilla, 3.0)
	draw_line(at, bxt, color_rejilla, 3.0)
	draw_line(at, byt, color_rejilla, 3.0)

	# Cierra visualmente ambos extremos para que cada segmento tenga vértices
	# claros y el usuario pueda colocar una pieza exactamente sobre el borde.
	var vertices := [
		Vector2i(0, 0),
		Vector2i(_ancho_editor, 0),
		Vector2i(0, _alto_editor),
	]
	for casilla in vertices:
		draw_circle(to_local(_posicion_muro_global(casilla, "")), 3.0,
			color_rejilla)

func _dibujar_lienzo_muros_vacio() -> void:
	if interior == null:
		return
	var esquina_global := _posicion_muro_global(Vector2i.ZERO, "")
	var extremo_x_global := _posicion_muro_global(Vector2i(_ancho_editor, 0), "")
	var extremo_y_global := _posicion_muro_global(Vector2i(0, _alto_editor), "")
	var altura := Vector2(0.0, -ALTURA_REJILLA_MURO_FISICA)
	var esquina := to_local(esquina_global)
	var extremo_x := to_local(extremo_x_global)
	var extremo_y := to_local(extremo_y_global)
	var panel_x := PackedVector2Array([esquina, extremo_x, extremo_x + altura, esquina + altura])
	var panel_y := PackedVector2Array([esquina, extremo_y, extremo_y + altura, esquina + altura])
	var alfa := 0.96 if not _mostrar_assets_muros else 0.14
	var relleno := Color("#5e5e73", alfa)
	draw_colored_polygon(panel_x, relleno)
	draw_colored_polygon(panel_y, relleno)
	var borde := Color("#252536", 0.92 if not _mostrar_assets_muros else 0.42)
	draw_polyline(PackedVector2Array([panel_x[0], panel_x[1], panel_x[2], panel_x[3], panel_x[0]]), borde, 2.0)
	draw_polyline(PackedVector2Array([panel_y[0], panel_y[1], panel_y[2], panel_y[3], panel_y[0]]), borde, 2.0)

func _dibujar_arista_muro(casilla: Vector2i, eje: String, color: Color) -> void:
	var puntos_globales := _puntos_celda_muro_global(casilla, eje)
	var puntos := PackedVector2Array()
	for punto in puntos_globales:
		puntos.append(to_local(punto))
	var ocupado := _buscar_muro_en_celda(casilla, eje)
	var hover := _hover_muro_casilla == casilla and _hover_muro_eje == eje
	var seleccionado := ocupado != null and _seleccionados.has(ocupado)
	# Cada celda mural es un panel editable, igual que una baldosa de suelo.
	# El relleno neutro evita que el usuario vea solo líneas flotantes; el
	# borde conserva la guía verde y cambia a interacción al seleccionar.
	var costura := Color("#252536", 0.82 if not _mostrar_assets_muros else 0.42)
	for banda in range(1, 4):
		var proporcion := float(banda) / 4.0
		var izquierda := puntos[0].lerp(puntos[3], proporcion)
		var derecha := puntos[1].lerp(puntos[2], proporcion)
		draw_line(izquierda, derecha, costura, 1.0)
	var color_borde := GlobalColors.get_color_interaccion() if seleccionado else color
	var grosor := 3.0 if (hover or seleccionado) else 2.0
	draw_polyline(PackedVector2Array([puntos[0], puntos[1], puntos[2], puntos[3], puntos[0]]), color_borde, grosor)
	if hover and not seleccionado:
		draw_colored_polygon(puntos, Color("#4a804d", 0.16))
		draw_polyline(PackedVector2Array([puntos[0], puntos[1], puntos[2], puntos[3], puntos[0]]), color_borde, grosor)
	draw_circle(puntos[0], 3.0, color_borde)
	draw_circle(puntos[2], 2.5, color_borde)
	return
	var clave := "muro_oeste" if eje == "x" else "muro_norte"
	var inicio_global := _posicion_muro_global(casilla, clave)
	var fin_global := inicio_global + _direccion_arista_muro(eje)
	var inicio := to_local(inicio_global)
	var fin := to_local(fin_global)
	var base_interior := interior.to_local(inicio_global)
	var arriba_global := interior.to_global(base_interior + Vector2(0.0, -ALTURA_REJILLA_MURO_FISICA))
	var delta_altura := to_local(arriba_global) - inicio
	var inicio_arriba := inicio + delta_altura
	var fin_arriba := fin + delta_altura
	# La pared debe leerse como una rejilla completa, igual que el piso.
	# No atenuamos laterales ni remate: todos los lados usan el mismo gris.
	var color_altura := color

	# Cada casilla de muro se representa como una caja vacía: base, dos
	# laterales y remate superior. No se dibuja ningún sprite de muro.
	var relleno_antiguo := Color(color.r, color.g, color.b, 0.10)
	draw_colored_polygon(PackedVector2Array([
		inicio, fin, fin_arriba, inicio_arriba
	]), relleno_antiguo)
	draw_line(inicio, fin, color, 2.5)
	draw_line(inicio, inicio_arriba, color_altura, 2.5)
	draw_line(fin, fin_arriba, color_altura, 2.5)
	draw_line(inicio_arriba, fin_arriba, color_altura, 2.5)
	draw_circle(inicio, 3.0, color)
	draw_circle(inicio_arriba, 2.5, color_altura)

func _dibujar_rombo_editor(casilla: Vector2i, color: Color) -> void:
	var centro := interior.to_global(Iso.centro(casilla.x, casilla.y))
	var puntos := PackedVector2Array([
		centro + Vector2(0, -Iso.MEDIO_Y),
		centro + Vector2(Iso.MEDIO_X, 0),
		centro + Vector2(0, Iso.MEDIO_Y),
		centro + Vector2(-Iso.MEDIO_X, 0),
		centro + Vector2(0, -Iso.MEDIO_Y),
	])
	draw_polyline(puntos, color, 2.0)

func _dibujar_diagnosticos() -> void:
	if _problemas_editor.is_empty():
		return
	for problema in _problemas_editor:
		var id := _id_desde_problema(problema)
		var nodo: Node2D = _elementos.get(id)
		if nodo == null or not is_instance_valid(nodo):
			continue
		var rect := Rect2(to_local(_rect_seleccion_global(nodo).position), _rect_seleccion_global(nodo).size).grow(5.0)
		draw_rect(rect, GlobalColors.PALETA["rojo_brillante"], false, 3.0)
		draw_circle(rect.position, 5.0, GlobalColors.PALETA["rojo_brillante"])

func _id_desde_problema(problema: String) -> String:
	var partes := problema.split(" ")
	if partes.is_empty():
		return ""
	if problema.begins_with("Solape:") and partes.size() >= 2:
		return partes[1]
	if partes.size() >= 1:
		return partes[0]
	return ""

func _dibujar_lienzo_base_vacio() -> void:
	if interior == null or interior.definicion == null:
		return
	# La rejilla normal ya se dibuja arriba con un único color. Aquí solo
	# dibujamos el contorno y el texto de estado; no repetimos las líneas para
	# evitar que se vean más gruesas o de otro tono al ocultar la base.
	var ancho := _ancho_editor
	var alto := _alto_editor
	var esquina_a := to_local(interior.to_global(Iso.centro(0, 0)))
	var esquina_b := to_local(interior.to_global(Iso.centro(ancho - 1, 0)))
	var esquina_c := to_local(interior.to_global(Iso.centro(ancho - 1, alto - 1)))
	var esquina_d := to_local(interior.to_global(Iso.centro(0, alto - 1)))
	draw_polyline(PackedVector2Array([esquina_a, esquina_b, esquina_c, esquina_d, esquina_a]), GlobalColors.get_color_interaccion(), 2.0)
	draw_string(ThemeDB.fallback_font, esquina_a + Vector2(-80, -24), "LIENZO BASE VACIO · coloca pisos y muros desde la paleta", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, GlobalColors.get_color_interaccion())

func _dibujar_subrejilla_tile(centro: Vector2) -> void:
	var mitad_x := Iso.MEDIO_X * 0.5
	var mitad_y := Iso.MEDIO_Y * 0.5
	var puntos_a := PackedVector2Array([
		centro + Vector2(0.0, -mitad_y),
		centro + Vector2(mitad_x, 0.0),
		centro + Vector2(0.0, mitad_y),
		centro + Vector2(-mitad_x, 0.0),
		centro + Vector2(0.0, -mitad_y),
	])
	draw_polyline(puntos_a, COLOR_SUBREJILLA_EDITOR, 1.0)
	var puntos_b := PackedVector2Array([
		centro + Vector2(0.0, 0.0),
		centro + Vector2(Iso.MEDIO_X, 0.0),
		centro + Vector2(0.0, Iso.MEDIO_Y),
		centro + Vector2(-Iso.MEDIO_X, 0.0),
		centro + Vector2(0.0, 0.0),
	])
	draw_polyline(puntos_b, COLOR_SUBREJILLA_EDITOR, 1.0)

func _dibujar_resaltado(nodo: Node2D, color: Color) -> void:
	if nodo == null or not is_instance_valid(nodo) or not nodo.visible:
		return
	if interior == null:
		return
	if nodo == _seleccionado or nodo == _hovered or _seleccionados.has(nodo):
		var rect := _rect_seleccion_global(nodo)
		var local_rect := Rect2(to_local(rect.position), rect.size)
		local_rect = local_rect.grow(3.0)
		draw_rect(local_rect, color, false, 3.0)
		return
	var casilla: Variant = nodo.get_meta("layout_casilla", null)
	var huella: Variant = nodo.get_meta("layout_huella", Vector2i.ONE)
	if casilla is Vector2i and huella is Vector2i:
		var origen: Vector2i = casilla
		var tamano: Vector2i = huella
		for dy in tamano.y:
			for dx in tamano.x:
				var centro_global := interior.to_global(Iso.centro(origen.x + dx, origen.y + dy))
				var centro := to_local(centro_global)
				var puntos := PackedVector2Array([
					centro + Vector2(0, -Iso.MEDIO_Y - 2),
					centro + Vector2(Iso.MEDIO_X + 2, 0),
					centro + Vector2(0, Iso.MEDIO_Y + 2),
					centro + Vector2(-Iso.MEDIO_X - 2, 0),
				])
				draw_polyline(PackedVector2Array([puntos[0], puntos[1], puntos[2], puntos[3], puntos[0]]), color, 3.0)

func _dibujar_nombre_hover(nodo: Node2D) -> void:
	var nombre := str(nodo.get_meta("layout_asset", nodo.get_meta("layout_id", "objeto")))
	var etiqueta := nombre.replace("interior.", "").replace("mueble.", "").replace("_", " ")
	var rect := _rect_seleccion_global(nodo)
	var posicion := to_local(Vector2(rect.position.x, rect.position.y - 5.0))
	var ancho := maxf(120.0, etiqueta.length() * 7.0 + 16.0)
	draw_rect(Rect2(posicion + Vector2(-4, -18), Vector2(ancho, 20)), Color("#172238cc"), true)
	draw_rect(Rect2(posicion + Vector2(-4, -18), Vector2(ancho, 20)), Color("#4a804d"), false, 1.0)
	draw_string(ThemeDB.fallback_font, posicion + Vector2(4, -4), etiqueta,
		HORIZONTAL_ALIGNMENT_LEFT, ancho - 8.0, 11, Color("#ffffff"))

func _dibujar_gizmo(nodo: Node2D) -> void:
	var rect := _rect_visual_global(nodo)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var local_rect := Rect2(to_local(rect.position), rect.size).grow(6.0)
	var centro := local_rect.get_center()
	var radio := maxf(24.0, minf(local_rect.size.x, local_rect.size.y) * 0.35)
	var color := GlobalColors.get_color_interaccion()
	draw_rect(local_rect, color, false, 2.0)
	draw_arc(centro, radio, -PI * 0.85, PI * 0.85, 24, Color(color, 0.72), 2.0)
	draw_circle(centro, 4.0, GlobalColors.get_color_seleccion())
	var manejadores := [
		local_rect.position,
		Vector2(local_rect.end.x, local_rect.position.y),
		local_rect.end,
		Vector2(local_rect.position.x, local_rect.end.y),
	]
	for punto in manejadores:
		draw_circle(punto, 4.0, color)
		draw_circle(punto, 2.0, GlobalColors.get_color_seleccion())
	# Asas laterales y flechas: arrastrar derecha = escala X, abajo = escala Y.
	# Las esquinas escalan proporcionalmente para conservar la forma del asset.
	var medio_derecho := Vector2(local_rect.end.x, centro.y)
	var medio_inferior := Vector2(centro.x, local_rect.end.y)
	_dibujar_asa_flecha(medio_derecho, Vector2.RIGHT, color)
	_dibujar_asa_flecha(medio_inferior, Vector2.DOWN, color)
	_dibujar_asa_flecha(local_rect.end, Vector2(1.0, 1.0).normalized(), color)

func _dibujar_asa_flecha(punto: Vector2, direccion: Vector2, color: Color) -> void:
	var d := direccion.normalized()
	var perpendicular := Vector2(-d.y, d.x)
	var inicio := punto - d * 12.0
	var punta := punto + d * 9.0
	draw_line(inicio, punta, color, 2.0)
	draw_colored_polygon(PackedVector2Array([
		punta,
		punta - d * 7.0 + perpendicular * 4.0,
		punta - d * 7.0 - perpendicular * 4.0,
	]), color)
	draw_circle(punto, 5.0, color)
	draw_circle(punto, 2.0, GlobalColors.get_color_seleccion())

func _gizmo_rect_global(nodo: Node2D) -> Rect2:
	return _rect_visual_global(nodo).grow(6.0)

func _iniciar_arrastre_gizmo(posicion: Vector2) -> bool:
	if _seleccionado == null or not is_instance_valid(_seleccionado):
		return false
	if _vista_limpia or _modo_colocacion or _calibrador == null:
		return false
	var rect := _gizmo_rect_global(_seleccionado)
	var mouse := get_global_mouse_position()
	var asas := {
		"esquina": rect.end,
		"x": Vector2(rect.end.x, rect.get_center().y),
		"y": Vector2(rect.get_center().x, rect.end.y),
	}
	var mejor := ""
	var distancia := 14.0
	for nombre in asas:
		var punto: Vector2 = asas[nombre]
		var actual := mouse.distance_to(punto)
		if actual <= distancia:
			distancia = actual
			mejor = nombre
	if mejor.is_empty():
		return false
	_gizmo_arrastrando = true
	_gizmo_manejador = mejor
	_gizmo_mouse_inicio = mouse
	_gizmo_rect_inicio = rect
	_gizmo_ajustes_inicio = _ajustes_visual_seleccionado().duplicate(true)
	_guardar_historial()
	_actualizar_estado("Escala visual: arrastra el asa; Esc cancela")
	return true

func _actualizar_arrastre_gizmo() -> void:
	if not _gizmo_arrastrando or _seleccionado == null or not is_instance_valid(_seleccionado):
		return
	var delta := get_global_mouse_position() - _gizmo_mouse_inicio
	var inicio := _gizmo_rect_inicio.size
	var factor_x := 1.0
	var factor_y := 1.0
	if inicio.x > 1.0 and (_gizmo_manejador == "x" or _gizmo_manejador == "esquina"):
		factor_x = maxf(0.10, (inicio.x + delta.x) / inicio.x)
	if inicio.y > 1.0 and (_gizmo_manejador == "y" or _gizmo_manejador == "esquina"):
		factor_y = maxf(0.10, (inicio.y + delta.y) / inicio.y)
	if _gizmo_manejador == "esquina":
		var factor := maxf(factor_x, factor_y)
		if delta.x + delta.y < 0.0:
			factor = minf(factor_x, factor_y)
		factor_x = factor
		factor_y = factor
	_aplicar_escala_gizmo(factor_x, factor_y)

func _aplicar_escala_gizmo(factor_x: float, factor_y: float) -> void:
	var ajustes := _gizmo_ajustes_inicio.duplicate(true)
	var escala: Array = ajustes.get("escala", [1.0, 1.0])
	var inicio := Vector2(float(escala[0]), float(escala[1])) if escala.size() >= 2 else Vector2.ONE
	var signo_x: float = -1.0 if inicio.x < 0.0 else 1.0
	var signo_y: float = -1.0 if inicio.y < 0.0 else 1.0
	var nuevo_x: float = clampf(absf(inicio.x) * factor_x, 0.10, 4.0) * signo_x
	var nuevo_y: float = clampf(absf(inicio.y) * factor_y, 0.10, 4.0) * signo_y
	ajustes["escala"] = [nuevo_x, nuevo_y]
	_aplicar_calibracion_a_nodo(_seleccionado, ajustes)
	_actualizar_calibrador_desde_seleccion()
	_actualizar_estado("Escala visual X %.2f · Y %.2f" % [nuevo_x, nuevo_y])
	queue_redraw()

func _finalizar_arrastre_gizmo() -> void:
	if not _gizmo_arrastrando:
		return
	_gizmo_arrastrando = false
	_gizmo_manejador = ""
	_actualizar_estado("Escala visual aplicada")
	_actualizar_panel()
	queue_redraw()

func _cancelar_arrastre_gizmo() -> void:
	if not _gizmo_arrastrando:
		return
	_gizmo_arrastrando = false
	_gizmo_manejador = ""
	if _seleccionado != null and is_instance_valid(_seleccionado):
		_aplicar_calibracion_a_nodo(_seleccionado, _gizmo_ajustes_inicio)
		_actualizar_calibrador_desde_seleccion()
	_actualizar_estado("Escala cancelada")
	queue_redraw()
