extends Node

## Regresión del Modo Desarrollador de Interiores.
## No modifica la partida real: monta el comparador en una instancia aislada,
## prueba ocultar/restaurar la base y comprueba que los muebles sobreviven.

const ComparadorScript := preload("res://scripts/comparador_herreria.gd")
var correctas := 0
var fallos := 0

func _ready() -> void:
	print("\n=== PRUEBAS DEL EDITOR DE INTERIORES ===\n")
	var comparador := ComparadorScript.new()
	add_child(comparador)
	await get_tree().process_frame
	await get_tree().process_frame

	var editor := comparador.get_node_or_null("InteriorLayoutEditor") as InteriorLayoutEditor
	# No dependemos del class_name para esta prueba: basta con comprobar el
	# nodo que el comparador monta con ese nombre.
	var interior: Node = null
	for hijo in comparador.get_children():
		if hijo.name.begins_with("Interior_"):
			interior = hijo
			break
	_comprobar(editor != null, "el editor se monta")
	_comprobar(interior != null, "el interior se monta")
	if editor != null:
		editor._ajustar_paleta_al_viewport()
		var paleta := editor._paleta
		var viewport_size := editor.get_viewport_rect().size
		var paleta_size := paleta.size if paleta != null else Vector2.ZERO
		_comprobar(paleta != null and paleta.position.x >= 0.0 and paleta.position.y >= 0.0, "la paleta queda dentro del viewport")
		_comprobar(paleta != null and paleta.position.x + paleta_size.x <= viewport_size.x + 1.0 and paleta.position.y + paleta_size.y <= viewport_size.y + 1.0, "la paleta no queda cortada por el borde de la ventana")
		var paleta_posicion_inicial := paleta.position if paleta != null else Vector2.ZERO
		editor._alternar_paleta()
		_comprobar(paleta != null and not paleta.visible, "la flecha puede plegar la paleta")
		editor._alternar_paleta()
		_comprobar(paleta != null and paleta.visible, "la flecha puede desplegar la paleta")
		if paleta != null:
			paleta.position = paleta_posicion_inicial + Vector2(40.0, -30.0)
			editor._paleta_posicionada_manualmente = true
			editor._ajustar_paleta_al_viewport()
		_comprobar(paleta.position != paleta_posicion_inicial, "la paleta conserva una posicion movida manualmente")
		_comprobar(editor._boton_mover_panel != null, "el panel del editor tiene manejador de arrastre")
		_comprobar(editor._boton_mover_comandos != null, "el panel de comandos tiene manejador de arrastre")
		_comprobar(editor._boton_mover_referencia != null, "la referencia tiene manejador de arrastre")
		if editor._boton_mover_panel != null and editor._boton_mover_comandos != null and editor._boton_mover_referencia != null:
			var panel_posicion_inicial: Vector2 = editor._panel.position
			var panel_handle: Vector2 = editor._boton_mover_panel.position + Vector2(5.0, 5.0)
			var panel_down := InputEventMouseButton.new()
			panel_down.button_index = MOUSE_BUTTON_LEFT
			panel_down.pressed = true
			panel_down.position = panel_handle
			editor._gestionar_arrastre_ui(panel_down)
			var panel_motion := InputEventMouseMotion.new()
			panel_motion.position = panel_handle + Vector2(25.0, 18.0)
			editor._gestionar_arrastre_ui(panel_motion)
			var panel_up := InputEventMouseButton.new()
			panel_up.button_index = MOUSE_BUTTON_LEFT
			panel_up.pressed = false
			panel_up.position = panel_motion.position
			editor._gestionar_arrastre_ui(panel_up)
			_comprobar(editor._panel.position != panel_posicion_inicial, "el panel del editor se puede arrastrar")
			editor._panel.position = panel_posicion_inicial
			editor._actualizar_flechas_paneles()

			var comandos_posicion_inicial: Vector2 = editor._panel_comandos.position
			var comandos_handle: Vector2 = editor._boton_mover_comandos.position + Vector2(5.0, 5.0)
			var comandos_down := InputEventMouseButton.new()
			comandos_down.button_index = MOUSE_BUTTON_LEFT
			comandos_down.pressed = true
			comandos_down.position = comandos_handle
			editor._gestionar_arrastre_ui(comandos_down)
			var comandos_motion := InputEventMouseMotion.new()
			comandos_motion.position = comandos_handle + Vector2(-20.0, -12.0)
			editor._gestionar_arrastre_ui(comandos_motion)
			var comandos_up := InputEventMouseButton.new()
			comandos_up.button_index = MOUSE_BUTTON_LEFT
			comandos_up.pressed = false
			comandos_up.position = comandos_motion.position
			editor._gestionar_arrastre_ui(comandos_up)
			_comprobar(editor._panel_comandos.position != comandos_posicion_inicial, "el panel de comandos se puede arrastrar")
			editor._panel_comandos.position = comandos_posicion_inicial
			editor._actualizar_flechas_paneles()

			var referencia_posicion_inicial: Vector2 = editor.referencia.position
			var referencia_handle: Vector2 = editor._boton_mover_referencia.position + Vector2(5.0, 5.0)
			var referencia_down := InputEventMouseButton.new()
			referencia_down.button_index = MOUSE_BUTTON_LEFT
			referencia_down.pressed = true
			referencia_down.position = referencia_handle
			editor._gestionar_arrastre_ui(referencia_down)
			var referencia_motion := InputEventMouseMotion.new()
			referencia_motion.position = referencia_handle + Vector2(-24.0, 16.0)
			editor._gestionar_arrastre_ui(referencia_motion)
			var referencia_up := InputEventMouseButton.new()
			referencia_up.button_index = MOUSE_BUTTON_LEFT
			referencia_up.pressed = false
			referencia_up.position = referencia_motion.position
			editor._gestionar_arrastre_ui(referencia_up)
			_comprobar(editor.referencia.position != referencia_posicion_inicial, "la referencia visual se puede arrastrar")
			editor.referencia.position = referencia_posicion_inicial
			editor._actualizar_flechas_paneles()
		var plantilla := editor._capturar_layout()
		plantilla["tipo"] = "plantilla_interior"
		var guardada := InteriorTemplateManager.guardar("_prueba_editor_layout", plantilla)
		var cargada := InteriorTemplateManager.cargar("_prueba_editor_layout")
		_comprobar(guardada, "la plantilla se guarda como datos planos")
		_comprobar(not cargada.is_empty() and cargada.get("tipo", "") == "plantilla_interior", "la plantilla se carga sin referencias a nodos")
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://data/desarrollador/plantillas/_prueba_editor_layout.json"))
	if editor == null or interior == null:
		_finalizar(comparador)
		return

	var suelo := _buscar_por_rol(interior, "suelo")
	var muro := _buscar_por_rol(interior, "muro")
	var mueble := _buscar_por_rol(interior, "mueble")
	_comprobar(suelo != null, "existe un suelo editable")
	_comprobar(muro != null, "existe un muro editable")
	_comprobar(mueble != null, "existe un mueble editable")
	if editor != null and suelo != null and mueble != null:
		editor._alternar_visibilidad_capa("base")
		_comprobar(not editor._capa_visible_para_editor(suelo), "la capa base puede ocultarse sin borrar el suelo")
		_comprobar(mueble.visible, "ocultar base conserva visibles los objetos")
		editor._alternar_visibilidad_capa("base")
		_comprobar(editor._capa_visible_para_editor(suelo), "la capa base puede restaurarse")
	if muro != null:
		var sprite_muro := _sprite_principal(muro)
		var escala_muro_original := sprite_muro.scale.y if sprite_muro != null else 0.0
		muro.set_meta("layout_altura_muro", 2)
		editor._aplicar_calibracion_a_nodo(muro, {})
		_comprobar(int(muro.get_meta("layout_altura_muro", 1)) == 2, "un muro acepta dos niveles de altura")
		_comprobar(sprite_muro != null and absf(sprite_muro.scale.y) > absf(escala_muro_original) * 1.9, "la altura visual crece sin cambiar la huella")
		var layout_altura: Dictionary = editor._capturar_layout()
		var muro_guardado: Dictionary = {}
		for entrada_altura in layout_altura.get("elementos", []):
			if str(entrada_altura.get("id", "")) == str(muro.get_meta("layout_id", "")):
				muro_guardado = entrada_altura
				break
		_comprobar(int(muro_guardado.get("altura_muro", 1)) == 2, "el layout guarda la altura del muro")
		muro.set_meta("layout_altura_muro", 1)
		editor._aplicar_calibracion_a_nodo(muro, {})
		editor._seleccionado = muro
		editor._gizmo_girar(90.0)
		_comprobar(is_equal_approx(float((muro.get_meta("layout_calibracion", {}) as Dictionary).get("rotacion", 0.0)), 90.0), "el gizmo gira el asset sin cambiar su huella")
		editor._gizmo_espejar_horizontal()
		var escala_gizmo: Array = (muro.get_meta("layout_calibracion", {}) as Dictionary).get("escala", [1.0, 1.0])
		_comprobar(escala_gizmo.size() >= 2 and float(escala_gizmo[0]) < 0.0, "el gizmo permite espejo horizontal")
		editor._gizmo_restaurar_orientacion()
		_comprobar(is_equal_approx(float((muro.get_meta("layout_calibracion", {}) as Dictionary).get("rotacion", 1.0)), 0.0), "el gizmo restaura la orientacion")
		muro.global_position += Vector2(7.0, 4.0)
		var problemas_muro: Array[String] = editor._diagnosticar_editor()
		var detecto_desalineacion := false
		for problema in problemas_muro:
			if problema.contains("desalineado"):
				detecto_desalineacion = true
		_comprobar(detecto_desalineacion, "el validador detecta un muro fuera de su ancla iso")
		editor._realinear_muros()
		var problemas_realineado: Array[String] = editor._diagnosticar_editor()
		var quedan_muros_desalineados := false
		for problema_realineado in problemas_realineado:
			if problema_realineado.contains("desalineado"):
				quedan_muros_desalineados = true
		_comprobar(not quedan_muros_desalineados, "realinear muros devuelve los nodos a la cuadricula Iso")
		muro.global_position = interior.to_global(Iso.centro_v(muro.get_meta("layout_casilla", Vector2i.ZERO)))
	var pisos := _buscar_todos_por_rol(interior, "suelo")
	var pisos_uniformes := true
	var pisos_aislados := true
	for piso in pisos:
		var sprite := _sprite_principal(piso)
		var atlas := sprite.texture as AtlasTexture if sprite != null else null
		if atlas == null or atlas.region.position.x != 0.0:
			pisos_uniformes = false
		if atlas == null or atlas.atlas == null or atlas.atlas.get_width() != 128 or atlas.atlas.get_height() != 64:
			pisos_aislados = false
	_comprobar(pisos.size() == interior.definicion.ancho * interior.definicion.alto,
		"el suelo crea una baldosa por casilla")
	_comprobar(pisos_uniformes, "todas las baldosas de piedra usan la variante base uniforme")
	_comprobar(pisos_aislados, "cada baldosa usa una textura aislada 128x64 sin sangrado del atlas")
	var muro_fila := _buscar_base_por_casilla(interior, "muro", Vector2i(1, 0))
	var muro_columna := _buscar_base_por_casilla(interior, "muro", Vector2i(0, 1))
	_comprobar(muro_fila != null and str(muro_fila.get_meta("layout_asset", "")) == interior.definicion.asset_muro_oeste,
		"la fila superior usa el muro que encadena hacia +X")
	_comprobar(muro_columna != null and str(muro_columna.get_meta("layout_asset", "")) == interior.definicion.asset_muro_norte,
		"la columna izquierda usa el muro que encadena hacia +Y")
	if muro_fila != null:
		editor._aplicar_asset(muro_fila, interior.definicion.asset_muro_norte)
		var problemas_eje := editor._diagnosticar_editor()
		var detecto_eje := false
		for problema_eje in problemas_eje:
			if problema_eje.contains("eje incorrecto"):
				detecto_eje = true
		_comprobar(detecto_eje, "el validador detecta un muro con asset del eje equivocado")
		editor._corregir_ejes_muros()
		_comprobar(str(muro_fila.get_meta("layout_asset", "")) == interior.definicion.asset_muro_oeste,
			"CORREGIR EJES restaura el asset correcto de la fila")
	if suelo == null or muro == null or mueble == null:
		_finalizar(comparador)
		return

	editor._pedir_borrado_modo(0)
	await get_tree().process_frame
	_comprobar(editor.is_inside_tree(), "el editor sigue vivo tras borrar la base")
	_comprobar(comparador.is_inside_tree(), "el comparador sigue vivo tras borrar la base")
	_comprobar(not suelo.visible, "el suelo se quita de la edición")
	_comprobar(not muro.visible, "el muro se quita de la edición")
	_comprobar(mueble.visible, "los muebles siguen visibles al borrar la base")

	var cantidad_antes_reemplazo: int = editor._elementos.size()
	var suelo_reemplazado: Node2D = editor._colocar_asset_en_tile(
		suelo.get_meta("layout_casilla", Vector2i.ZERO),
		str(suelo.get_meta("layout_asset", "interior.herreria_v1.suelo_piedra")))
	var muro_reemplazado: Node2D = editor._colocar_asset_en_tile(
		muro.get_meta("layout_casilla", Vector2i.ZERO),
		str(muro.get_meta("layout_asset", "interior.herreria_v1.muro_norte")))
	_comprobar(suelo_reemplazado == suelo, "un piso nuevo reutiliza el slot oculto")
	_comprobar(muro_reemplazado == muro, "un muro nuevo reutiliza el slot oculto")
	_comprobar(editor._elementos.size() == cantidad_antes_reemplazo, "reemplazar no crea stacking de nodos")

	editor._pedir_borrado_modo(0)
	await get_tree().process_frame
	_comprobar(suelo.visible, "el suelo se restaura")
	_comprobar(muro.visible, "el muro se restaura")

	editor._pedir_borrado_modo(1)
	await get_tree().process_frame
	_comprobar(not mueble.visible, "el borrado de objetos es independiente")
	editor._pedir_borrado_modo(1)
	await get_tree().process_frame
	_comprobar(mueble.visible, "los objetos se restauran")

	var definicion: InteriorDefinicion = interior.definicion
	var ancho_original := definicion.ancho
	var alto_original := definicion.alto
	var elementos_antes_tamano: int = editor._elementos.size()
	var layout_original: Dictionary = editor._capturar_layout()
	editor._cambiar_tamano_editor(1, 1)
	_comprobar(editor._ancho_editor == ancho_original + 1, "aumentar ancho funciona")
	_comprobar(editor._alto_editor == alto_original + 1, "aumentar alto funciona")
	var piso_nuevo: Node2D = editor._buscar_base_en_casilla(Vector2i(ancho_original, alto_original), "suelo")
	_comprobar(piso_nuevo != null and piso_nuevo.visible, "la ampliacion crea la casilla de suelo")
	var id_piso_nuevo := str(piso_nuevo.get_meta("layout_id", "")) if piso_nuevo != null else ""
	editor._cambiar_tamano_editor(-1, -1)
	_comprobar(editor._ancho_editor == ancho_original and editor._alto_editor == alto_original, "reducir devuelve el tamaño original")
	_comprobar(piso_nuevo != null and not piso_nuevo.visible, "la casilla fuera de tamaño se oculta")
	editor._cambiar_tamano_editor(1, 1)
	var piso_reactivado: Node2D = editor._buscar_base_en_casilla(Vector2i(ancho_original, alto_original), "suelo")
	_comprobar(piso_reactivado != null and piso_reactivado.visible, "ampliar de nuevo reactiva la casilla")
	_comprobar(str(piso_reactivado.get_meta("layout_id", "")) == id_piso_nuevo, "ampliar de nuevo reutiliza el mismo nodo")
	_comprobar(editor._elementos.size() == elementos_antes_tamano + ancho_original + alto_original + 3, "no se crean duplicados al alternar tamaño")
	_comprobar(definicion.ancho == ancho_original and definicion.alto == alto_original, "la definición compartida no se modifica")
	_comprobar((layout_original.get("tamano", []) as Array).size() == 2, "el layout guarda ancho y alto")
	editor._aplicar_layout(layout_original)
	_comprobar(editor._ancho_editor == ancho_original and editor._alto_editor == alto_original, "el layout restaura el tamaño")

	var interior_real := interior as InteriorEscena
	var puerta := _buscar_por_id(interior, "puerta_salida")
	var transiciones_antes: int = interior_real.transiciones.size()
	_comprobar(puerta != null and str(puerta.get_meta("layout_role", "")) == "transicion", "la puerta de salida es editable como transicion")
	if puerta != null:
		var casilla_puerta_original: Vector2i = puerta.get_meta("layout_casilla", Vector2i.ZERO)
		editor._reposicionar_transicion(puerta, casilla_puerta_original + Vector2i(1, 0))
		_comprobar(puerta.get_meta("layout_casilla", Vector2i.ZERO) == casilla_puerta_original + Vector2i(1, 0), "la puerta puede moverse a otra casilla")
		_comprobar((puerta as Puerta).casilla_propia == casilla_puerta_original + Vector2i(1, 0), "la puerta funcional actualiza su casilla real")

	editor._validar_base_y_cambiar_modo()
	var casilla_nueva := _buscar_casilla_libre(editor, interior, Vector2i(1, 1))
	var escalera := editor._colocar_asset_en_tile(casilla_nueva, "mueble.comun.escalera_madera")
	_comprobar(escalera != null and str(escalera.get_meta("layout_role", "")) == "transicion", "se puede crear una escalera como transicion")
	_comprobar(escalera != null and interior_real.transiciones.has(escalera), "la escalera nueva queda registrada en InteriorEscena")
	if escalera != null:
		editor._seleccionado = escalera
		editor._seleccionados = [escalera]
		editor._actualizar_editor_transicion(escalera)
		editor._destino_zona_edit.text = "interior_taberna_pb"
		editor._entrada_destino_x.value = 2
		editor._entrada_destino_y.value = 3
		editor._accion_transicion_edit.text = "Bajar"
		editor._aplicar_datos_transicion()
		_comprobar(str(escalera.get_meta("layout_destino_zona", "")) == "interior_taberna_pb", "la escalera guarda zona destino")
		_comprobar(escalera.entrada_destino == Vector2i(2, 3), "la escalera guarda entrada destino")
		_comprobar(escalera.accion == "Bajar", "la escalera guarda la accion")
		var layout_transicion: Dictionary = editor._capturar_layout()
		editor._quitar_transicion_seleccionada()
		_comprobar(not escalera.visible and escalera.process_mode == Node.PROCESS_MODE_DISABLED, "quitar transicion la oculta y desactiva")
		editor._restaurar_seleccionado()
		_comprobar(escalera.visible and escalera.process_mode == Node.PROCESS_MODE_INHERIT, "restaurar transicion la reactiva")
		editor._reposicionar_transicion(escalera, casilla_nueva + Vector2i(1, 0))
		editor._aplicar_layout(layout_transicion)
		_comprobar(escalera.get_meta("layout_casilla", Vector2i.ZERO) == casilla_nueva, "cargar layout devuelve la transicion a su casilla")
		_comprobar(escalera.entrada_destino == Vector2i(2, 3) and escalera.accion == "Bajar", "cargar layout restaura datos funcionales")
		var cantidad_transiciones: int = interior_real.transiciones.size()
		editor._quitar_transicion_seleccionada()
		var reactivada := editor._colocar_asset_en_tile(casilla_nueva, "mueble.comun.escalera_madera")
		_comprobar(reactivada == escalera, "recolocar reutiliza la transicion oculta")
		_comprobar(interior_real.transiciones.size() == cantidad_transiciones, "recolocar no duplica transiciones funcionales")
	_comprobar(interior_real.transiciones.size() >= transiciones_antes, "la lista de transiciones queda estable")

	# Un asset creado desde la paleta no existe al reconstruir la escena desde
	# cero. Esta prueba simula exactamente ese caso: el JSON contiene el nodo,
	# pero el nodo no está en _elementos todavía.
	var casilla_persistencia := _buscar_casilla_libre(editor, interior, Vector2i(1, 1))
	var id_persistencia := "asset_editor_997"
	var layout_persistencia: Dictionary = editor._capturar_layout()
	var entrada_persistencia := {
		"id": id_persistencia,
		"rol": "mueble",
		"asset": "mueble.herreria.yunque",
		"casilla": [casilla_persistencia.x, casilla_persistencia.y],
		"huella": [1, 1],
		"solido": true,
		"offset_px": [0, 0],
		"calibracion": {},
		"altura_muro": 1,
		"rotacion": 0.0,
		"espejo_x": false,
		"espejo_y": false,
		"visible": true,
	}
	(layout_persistencia["elementos"] as Array).append(entrada_persistencia)
	editor._aplicar_layout(layout_persistencia)
	var persistido: Node2D = editor._elementos.get(id_persistencia)
	_comprobar(persistido != null and is_instance_valid(persistido), "el layout recrea un asset nuevo que no existia en la escena")
	_comprobar(persistido != null and persistido.get_meta("layout_casilla", Vector2i.ZERO) == casilla_persistencia and str(persistido.get_meta("layout_asset", "")) == "mueble.herreria.yunque", "el asset recreado conserva casilla y clave")

	# Round-trip real: serializa el diccionario a JSON, destruye el comparador y
	# reconstruye otra instancia antes de cargarlo. Esto cubre el cierre/reinicio
	# que no puede detectar una prueba que solo llama _aplicar_layout en memoria.
	var ruta_roundtrip: String = "user://_prueba_editor_layout_roundtrip.json"
	var archivo_roundtrip: FileAccess = FileAccess.open(ruta_roundtrip, FileAccess.WRITE)
	var texto_roundtrip: String = JSON.stringify(layout_persistencia)
	if archivo_roundtrip != null:
		archivo_roundtrip.store_string(texto_roundtrip)
		archivo_roundtrip.close()
	_comprobar(archivo_roundtrip != null, "el layout se escribe como JSON plano")
	var datos_roundtrip: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta_roundtrip))
	_comprobar(datos_roundtrip is Dictionary and (datos_roundtrip as Dictionary).has("elementos"), "el JSON guardado se puede leer")

	comparador.queue_free()
	await get_tree().process_frame
	var comparador_reconstruido: Node = ComparadorScript.new()
	add_child(comparador_reconstruido)
	await get_tree().process_frame
	await get_tree().process_frame
	var editor_reconstruido := comparador_reconstruido.get_node_or_null("InteriorLayoutEditor") as InteriorLayoutEditor
	_comprobar(editor_reconstruido != null, "el editor se reconstruye en una segunda instancia")
	if editor_reconstruido != null and datos_roundtrip is Dictionary:
		editor_reconstruido._aplicar_layout(datos_roundtrip as Dictionary)
		var persistido_reconstruido: Node2D = editor_reconstruido._elementos.get(id_persistencia)
		_comprobar(persistido_reconstruido != null and is_instance_valid(persistido_reconstruido), "el asset nuevo reaparece tras reconstruir y cargar el JSON")
		_comprobar(persistido_reconstruido != null and persistido_reconstruido.get_meta("layout_casilla", Vector2i.ZERO) == casilla_persistencia, "la posicion del asset sobrevive al round-trip")
		_comprobar(persistido_reconstruido != null and str(persistido_reconstruido.get_meta("layout_asset", "")) == "mueble.herreria.yunque", "la clave del asset sobrevive al round-trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_roundtrip))

	_finalizar(comparador_reconstruido)

func _buscar_por_rol(nodo: Node, rol: String) -> Node2D:
	if nodo is Node2D and str(nodo.get_meta("layout_role", "")) == rol:
		return nodo as Node2D
	for hijo in nodo.get_children():
		var encontrado := _buscar_por_rol(hijo, rol)
		if encontrado != null:
			return encontrado
	return null

func _buscar_por_id(nodo: Node, id: String) -> Node2D:
	if nodo is Node2D and str(nodo.get_meta("layout_id", "")) == id:
		return nodo as Node2D
	for hijo in nodo.get_children():
		var encontrado := _buscar_por_id(hijo, id)
		if encontrado != null:
			return encontrado
	return null

func _buscar_todos_por_rol(nodo: Node, rol: String) -> Array[Node2D]:
	var encontrados: Array[Node2D] = []
	if nodo is Node2D and str(nodo.get_meta("layout_role", "")) == rol:
		encontrados.append(nodo as Node2D)
	for hijo in nodo.get_children():
		encontrados.append_array(_buscar_todos_por_rol(hijo, rol))
	return encontrados

func _buscar_base_por_casilla(nodo: Node, rol: String, casilla: Vector2i) -> Node2D:
	for candidato in _buscar_todos_por_rol(nodo, rol):
		if candidato.get_meta("layout_casilla", Vector2i(-999, -999)) == casilla:
			return candidato
	return null

func _sprite_principal(nodo: Node2D) -> Sprite2D:
	if nodo is Sprite2D:
		return nodo as Sprite2D
	for hijo in nodo.get_children():
		if hijo is Sprite2D:
			return hijo as Sprite2D
		if hijo is Node2D:
			var encontrado := _sprite_principal(hijo as Node2D)
			if encontrado != null:
				return encontrado
	return null

func _buscar_casilla_libre(editor: InteriorLayoutEditor, interior: Node, inicio: Vector2i) -> Vector2i:
	for y in range(inicio.y, editor._alto_editor):
		for x in range(inicio.x, editor._ancho_editor):
			var casilla := Vector2i(x, y)
			var ocupada := false
			for id in editor._orden_ids:
				var nodo: Node2D = editor._elementos.get(id)
				if nodo == null or not is_instance_valid(nodo) or not nodo.visible:
					continue
				var rol := str(nodo.get_meta("layout_role", ""))
				if rol != "mueble" and rol != "transicion":
					continue
				var origen: Vector2i = nodo.get_meta("layout_casilla", Vector2i(-99, -99))
				var huella: Vector2i = nodo.get_meta("layout_huella", Vector2i.ONE)
				if editor._rect_tiles_solapan(casilla, Vector2i.ONE, origen, huella):
					ocupada = true
					break
			if not ocupada:
				return casilla
	return inicio

func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		correctas += 1
		print("  OK    %s" % mensaje)
	else:
		fallos += 1
		print("  FAIL  %s" % mensaje)

func _finalizar(comparador: Node) -> void:
	if is_instance_valid(comparador):
		comparador.queue_free()
	print("\n=== %d/%d correctas ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)
