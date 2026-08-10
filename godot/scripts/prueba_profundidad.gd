extends Node2D
## Banco visual de profundidad. No es una prueba automática: genera cinco
## capturas para mirarlas con los ojos.
##
## Comprueba lo único que no se puede demostrar con aserciones: que el tejado
## del edificio del kit NO tapa a un actor que pasa por delante, y que sí lo
## tapa cuando pasa por detrás. Es el fallo clásico de `z_index` en un mundo
## ordenado por profundidad, y sólo se ve mirando.
##
## Uso:
##   Godot_..._win64.exe --path <godot> res://escenas/prueba_profundidad.tscn \
##       --resolution 1100x700 -- --carpeta=<ruta salida>

const CLAVE := "edificio.kit_casa"
const CASILLA := Vector2i(6, 6)

var edificio: EdificioVisual
var actor: Actor
var _etiqueta: Label
var _objetos: Node2D

func _ready() -> void:
	# Esta escena existe para inspección visual. En headless no hay una
	# superficie de presentación fiable para capturar el viewport; salir limpio
	# mantiene la regresión automática separada de la prueba manual de arte.
	if DisplayServer.get_name() == "headless":
		print("Prueba de profundidad: captura omitida en headless; usar ventana para revisar PNGs.")
		get_tree().quit(0)
		return
	_montar()
	await _capturar_estados()
	get_tree().quit(0)

func _montar() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color("2b3a30")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	var capa_fondo := CanvasLayer.new()
	capa_fondo.layer = -1
	capa_fondo.add_child(fondo)
	add_child(capa_fondo)

	# Rejilla de suelo, para leer las casillas
	var suelo := Node2D.new()
	suelo.z_index = Capas.TERRENO
	add_child(suelo)
	suelo.draw.connect(func(): pass)
	_dibujar_rejilla(suelo)

	_objetos = Node2D.new()
	_objetos.name = "Objetos"
	_objetos.y_sort_enabled = true
	_objetos.z_index = Capas.MUNDO
	add_child(_objetos)

	edificio = EdificioVisual.new()
	_objetos.add_child(edificio)
	edificio.montar_kit("kit_casa", CLAVE, CASILLA)

	actor = Actor.new()
	_objetos.add_child(actor)

	var cam := CamaraIsla.new()
	add_child(cam)
	cam.make_current()
	cam.modo_pixel = true
	cam.zoom_a_nivel(1)                     ## 1.0, nítido
	cam.seguir(null)
	cam.sin_limites()
	cam.position = Iso.centro(CASILLA.x + 1, CASILLA.y + 1) + Vector2(0, -40)

	var capa := CanvasLayer.new()
	capa.layer = Capas.CAPA_HUD
	add_child(capa)
	_etiqueta = Label.new()
	_etiqueta.position = Vector2(16, 12)
	_etiqueta.add_theme_font_size_override("font_size", 20)
	_etiqueta.add_theme_color_override("font_color", GlobalColors.color("luz_palida"))
	_etiqueta.add_theme_color_override("font_outline_color",
		GlobalColors.con_alpha("vacio_abismal", 0.9))
	_etiqueta.add_theme_constant_override("outline_size", 8)
	capa.add_child(_etiqueta)

func _dibujar_rejilla(nodo: Node2D) -> void:
	var lineas := Line2D.new()
	nodo.add_child(lineas)
	for y in range(0, 14):
		for x in range(0, 14):
			var l := Line2D.new()
			l.width = 1.0
			l.default_color = GlobalColors.con_alpha("plata_salitre", 0.10)
			var c := Iso.centro(x, y)
			l.points = PackedVector2Array([
				c + Vector2(0, -Iso.MEDIO_Y), c + Vector2(Iso.MEDIO_X, 0),
				c + Vector2(0, Iso.MEDIO_Y), c + Vector2(-Iso.MEDIO_X, 0),
				c + Vector2(0, -Iso.MEDIO_Y)])
			nodo.add_child(l)

# ---------------------------------------------------------------------------

func _capturar_estados() -> void:
	var carpeta := "user://"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--carpeta="):
			carpeta = arg.substr(10)

	var detras := Vector2(CASILLA.x - 1, CASILLA.y - 1)
	var junto := Vector2(CASILLA.x + 3, CASILLA.y - 1)
	var delante := Vector2(CASILLA.x + 3.5, CASILLA.y + 3.5)

	var estados := [
		["1_actor_detras", detras, true],
		["2_actor_junto", junto, true],
		["3_actor_delante", delante, true],
		["4_tejado_visible", delante, true],
		["5_tejado_oculto", delante, false],
	]
	for e in estados:
		var nombre: String = e[0]
		actor.colocar(e[1])
		edificio.mostrar_tejado(bool(e[2]))
		_etiqueta.text = "%s   ·   actor %s   ·   tejado %s   ·   zoom %.1f" % [
			nombre, actor.pos_tile,
			"visible" if edificio.tejado_visible() else "oculto",
			(get_viewport().get_camera_2d() as CamaraIsla).zoom.x]
		await _guardar("%s/%s.png" % [carpeta, nombre])
	print("Capturas de profundidad en %s" % carpeta)

func _guardar(ruta: String) -> void:
	await get_tree().process_frame
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ruta)
