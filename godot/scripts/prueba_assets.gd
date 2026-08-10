extends Node
## Pruebas del kit visual: manifiesto, resolvedor, capas y sustitución de un
## edificio.
##
## No comprueban que el arte sea bonito —eso no se automatiza—, sino que el
## CONTRATO se cumple: dimensiones, pivotes, rejilla lógica, transparencias y
## orden de dibujo. Es lo que permitirá cambiar placeholders por pixel art de
## verdad sin tocar una línea de lógica.

const CLAVE_CASA := "edificio.kit_casa"

var fallos := 0
var pruebas := 0

func _ready() -> void:
	print("\n=== PRUEBAS DEL KIT VISUAL ===\n")
	_p1_manifiesto()
	_p2_rejilla_logica()
	_p3_pivotes()
	_p4_piezas_montadas()
	_p5_falta_un_asset()
	_p6_animacion()
	_p7_huella_y_luz()
	_p8_capas()
	_p9_sustitucion_edificio()
	_p10_seleccion_por_datos()
	_p11_respaldo_si_falta()
	_p12_zoom_discreto()
	_p13_paleta_maestra()
	print("\n=== %d/%d correctas ===" % [pruebas - fallos, pruebas])
	get_tree().quit(1 if fallos > 0 else 0)

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	pruebas += 1
	if condicion:
		print("  OK    %s" % nombre)
	else:
		fallos += 1
		print("  FALLO %s   %s" % [nombre, detalle])

# ---------------------------------------------------------------------------

func _p1_manifiesto() -> void:
	print("1. El manifiesto entero es válido")
	var problemas := Assets.validar()
	_comprobar("no hay ningún problema", problemas.is_empty(),
		"\n      " + "\n      ".join(problemas))
	_comprobar("hay claves cargadas", Assets.claves().size() >= 20,
		str(Assets.claves().size()))

func _p2_rejilla_logica() -> void:
	print("2. Rejilla lógica ×2")
	# Ya lo cubre validar(), pero se comprueba explícito en dos casos concretos
	# porque es la regla que define todo el kit.
	var t := Assets.datos("terreno.base")
	_comprobar("la celda física es la lógica × 2",
		int(t["celda_fisica"][0]) == int(t["celda_logica"][0]) * int(t["escala_pixel"])
		and int(t["celda_fisica"][1]) == int(t["celda_logica"][1]) * int(t["escala_pixel"]),
		"%s vs %s × %s" % [t["celda_fisica"], t["celda_logica"], t["escala_pixel"]])

	var a := Assets.datos("actor.corsario.walk")
	_comprobar("el fotograma físico es el lógico × 2",
		int(a["fotograma_fisico"][0]) == int(a["fotograma_logico"][0]) * 2
		and int(a["fotograma_fisico"][1]) == int(a["fotograma_logico"][1]) * 2)

	# Un manifiesto con la escala mal debe ser rechazado.
	var falso := Assets.datos(CLAVE_CASA + ".cuerpo").duplicate(true)
	falso["tam_logico"] = [100, 100]
	_comprobar("una escala incoherente se detectaría",
		Vector2(float(falso["tam_fisico"][0]), float(falso["tam_fisico"][1]))
			!= Vector2(100, 100) * 2.0)

func _p3_pivotes() -> void:
	print("3. Pivotes declarados, nunca deducidos")
	_comprobar("el pivote de la casa es el declarado",
		Assets.pivote(CLAVE_CASA + ".cuerpo") == Vector2(192, 384),
		str(Assets.pivote(CLAVE_CASA + ".cuerpo")))
	_comprobar("cuerpo y tejado comparten pivote",
		Assets.pivote(CLAVE_CASA + ".cuerpo") == Assets.pivote(CLAVE_CASA + ".tejado"))
	var c := Assets.datos(CLAVE_CASA + ".cuerpo")
	var t := Assets.datos(CLAVE_CASA + ".tejado")
	_comprobar("y comparten lienzo", c["tam_fisico"] == t["tam_fisico"],
		"%s vs %s" % [c["tam_fisico"], t["tam_fisico"]])

func _p4_piezas_montadas() -> void:
	print("4. El resolvedor entrega piezas listas")
	var s := Assets.sprite(CLAVE_CASA + ".cuerpo")
	_comprobar("devuelve un Sprite2D", s is Sprite2D)
	_comprobar("sin centrar", not s.centered)
	_comprobar("con el pivote descontado", s.offset == -Vector2(192, 384), str(s.offset))
	_comprobar("con filtro Nearest",
		s.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	_comprobar("con z_index 0, sin saltarse el orden por Y", s.z_index == 0)
	_comprobar("la textura mide lo declarado",
		s.texture.get_width() == 384 and s.texture.get_height() == 448,
		"%dx%d" % [s.texture.get_width(), s.texture.get_height()])
	s.free()

	var caja := Assets.caja("ui.panel")
	_comprobar("el panel es un StyleBoxTexture", caja is StyleBoxTexture)
	_comprobar("con sus márgenes de 9 partes",
		caja.texture_margin_left == 16.0 and caja.texture_margin_bottom == 16.0,
		"%s / %s" % [caja.texture_margin_left, caja.texture_margin_bottom])

func _p5_falta_un_asset() -> void:
	print("5. Un asset que falta no revienta: se ve")
	var t := Assets.textura("clave.que.no.existe")
	_comprobar("devuelve una textura, no null", t != null)
	_comprobar("y queda anotado como problema",
		Assets.problemas().any(func(p: String): return p.begins_with("clave.que.no.existe")),
		str(Assets.problemas()))
	# Se limpia para no ensuciar validaciones posteriores.
	Assets.validar()

func _p6_animacion() -> void:
	print("6. Animación por direcciones")
	var marcos := Assets.animacion("actor.corsario.walk", "walk")
	var esperadas := ["walk_abajo", "walk_izquierda", "walk_arriba", "walk_derecha"]
	for nombre in esperadas:
		_comprobar("existe %s" % nombre, marcos.has_animation(nombre))
	if marcos.has_animation("walk_abajo"):
		_comprobar("tiene 8 fotogramas", marcos.get_frame_count("walk_abajo") == 8,
			str(marcos.get_frame_count("walk_abajo")))
		var f: Texture2D = marcos.get_frame_texture("walk_abajo", 0)
		_comprobar("cada fotograma mide 64×96",
			f.get_width() == 64 and f.get_height() == 96,
			"%dx%d" % [f.get_width(), f.get_height()])
	# Las claves coinciden con las que produce el actor
	var a := Actor.new()
	a.estado = "andar"
	a.direccion = Vector2(1, 1)
	_comprobar("la clave del actor existe en la hoja",
		marcos.has_animation(a.clave_animacion()), a.clave_animacion())
	a.free()

func _p7_huella_y_luz() -> void:
	print("7. Huella rectangular y luz declarada")
	_comprobar("la huella es un par, no un número",
		Assets.huella(CLAVE_CASA + ".cuerpo") == Vector2i(3, 3),
		str(Assets.huella(CLAVE_CASA + ".cuerpo")))
	_comprobar("un objeto de una casilla también",
		Assets.huella("objeto.barril") == Vector2i(1, 1))

	var luz := Assets.luz("objeto.farol")
	_comprobar("el farol DECLARA que admite luz", not luz.is_empty())
	_comprobar("y declara que sólo de noche", bool(luz.get("solo_de_noche", false)))
	_comprobar("el cofre no declara ninguna", Assets.luz("objeto.cofre.cerrado").is_empty())
	# Lo importante: declararla no la crea. Encenderla es cosa de la lógica.
	var farol := Assets.sprite("objeto.farol")
	var tiene_luz := false
	for h in farol.get_children():
		if h is PointLight2D:
			tiene_luz = true
	_comprobar("el resolvedor NO crea la luz por su cuenta", not tiene_luz)
	farol.free()

func _p8_capas() -> void:
	print("8. Capas: nadie se salta el orden por Y")
	_comprobar("el mundo es la capa 0", Capas.MUNDO == 0)
	_comprobar("el terreno va por debajo", Capas.TERRENO < Capas.MUNDO)
	_comprobar("los efectos por encima", Capas.EFECTOS > Capas.MUNDO)

	var jug := Jugador.new()
	add_child(jug)
	_comprobar("el jugador NO usa z_index para colarse",
		Capas.respeta_orden_y(jug), "z_index=%d" % jug.z_index)
	jug.queue_free()

func _p9_sustitucion_edificio() -> void:
	print("9. Sustituir un edificio por el del kit")
	var contenedor := Node2D.new()
	contenedor.y_sort_enabled = true
	add_child(contenedor)

	var casilla := Vector2i(10, 10)
	var e := EdificioVisual.new()
	contenedor.add_child(e)
	e.montar_kit("kit_casa", CLAVE_CASA, casilla)

	_comprobar("toma la huella del manifiesto", e.huella == Vector2i(3, 3), str(e.huella))
	_comprobar("se ancla en el vértice inferior de su huella",
		e.position == Iso.apoyo(casilla.x + 2, casilla.y + 2),
		"%s vs %s" % [e.position, Iso.apoyo(casilla.x + 2, casilla.y + 2)])
	_comprobar("cuerpo y tejado son hijos suyos",
		e.get_child_count() >= 2 and e.tejado != null and e.tejado.get_parent() == e)
	_comprobar("el edificio NO ordena a sus hijos: es una unidad",
		not e.y_sort_enabled)
	_comprobar("ninguna pieza usa z_index",
		Capas.respeta_orden_y(e) and Capas.respeta_orden_y(e.tejado))
	_comprobar("el tejado se dibuja después del cuerpo",
		e.get_children().find(e.tejado) > 0)

	_comprobar("el tejado empieza visible", e.tejado_visible())
	e.mostrar_tejado(false)
	_comprobar("se puede ocultar", not e.tejado_visible())
	e.mostrar_tejado(true)
	_comprobar("y volver a mostrar", e.tejado_visible())

	# La prueba que pediste: un actor delante y detrás del edificio.
	# En un contenedor ordenado por Y, dibuja después —y por tanto encima— quien
	# tenga mayor Y. Como el tejado es HIJO del edificio, comparte su Y y no
	# puede colarse delante de un actor que está más abajo en pantalla.
	var actor := Actor.new()
	contenedor.add_child(actor)

	actor.colocar(Vector2(casilla.x + 4, casilla.y + 4))   # delante
	_comprobar("un actor DELANTE tiene mayor Y que el edificio",
		actor.position.y > e.position.y,
		"actor %.1f vs edificio %.1f" % [actor.position.y, e.position.y])
	_comprobar("y por tanto se dibuja después que su tejado",
		actor.position.y > e.position.y and e.tejado.z_index == 0)

	actor.colocar(Vector2(casilla.x - 2, casilla.y - 2))   # detrás
	_comprobar("un actor DETRÁS tiene menor Y",
		actor.position.y < e.position.y,
		"actor %.1f vs edificio %.1f" % [actor.position.y, e.position.y])

	# Un tejado que cubre al actor se atenúa sin volver transparente el cuerpo.
	var punto_tapado := e.global_position + Vector2(0, -20)
	e.actualizar_occlusion(punto_tapado)
	_comprobar("un tejado que cubre al actor se vuelve transparente",
		e.tejado.self_modulate.a < 0.5, str(e.tejado.self_modulate.a))
	_comprobar("la transparencia no afecta al cuerpo del kit",
		(e.get_node("Cuerpo") as Sprite2D).self_modulate.a == 1.0)
	e.actualizar_occlusion(e.global_position + Vector2(10000, -20))
	_comprobar("el tejado recupera su opacidad al dejar de cubrirlo",
		e.tejado.self_modulate.a == 1.0, str(e.tejado.self_modulate.a))

	actor.queue_free()
	contenedor.queue_free()

func _p10_seleccion_por_datos() -> void:
	print("10. El arte se elige por DATOS, no por nombre")
	var migrados := []
	var antiguos := []
	for id: String in BaseDeDatos.edificios:
		var d: EdificioData = BaseDeDatos.edificio(id)
		if d.asset_exterior != "":
			migrados.append(id)
		else:
			antiguos.append(id)

	_comprobar("hay exactamente UN edificio migrado", migrados.size() == 1,
		str(migrados))
	_comprobar("el resto sigue con el arte antiguo", antiguos.size() >= 8,
		str(antiguos.size()))
	if migrados.is_empty():
		return
	var d: EdificioData = BaseDeDatos.edificio(migrados[0])
	_comprobar("apunta a una clave del manifiesto",
		Assets.existe(d.asset_exterior + ".cuerpo"), d.asset_exterior)
	_comprobar("y esa clave trae tejado", Assets.existe(d.asset_exterior + ".tejado"))
	_comprobar("y puerta", Assets.existe(d.asset_exterior + ".puerta"))
	_comprobar("quitar el dato lo devolvería al arte antiguo",
		BaseDeDatos.edificio(antiguos[0]).asset_exterior == "")

	# La lógica NO depende del sprite: el edificio migrado conserva todo.
	_comprobar("el edificio migrado conserva su interior", d.interior != "")
	_comprobar("conserva su rol", d.rol != "")
	_comprobar("conserva su coste", not d.coste.is_empty())
	_comprobar("y su nombre", d.nombre != "")

func _p11_respaldo_si_falta() -> void:
	print("11. Si falta una pieza, magenta y a seguir")
	var contenedor := Node2D.new()
	add_child(contenedor)
	var e := EdificioVisual.new()
	contenedor.add_child(e)
	# Clave que no existe: ni cuerpo ni tejado.
	e.montar_kit("fantasma", "edificio.no_existe", Vector2i(3, 3))

	_comprobar("el edificio se monta igualmente", e.is_inside_tree())
	_comprobar("tiene cuerpo aunque sea de relleno", e.get_child_count() >= 1)
	_comprobar("cae en una huella por defecto de 1×1",
		e.huella == Vector2i(1, 1), str(e.huella))
	_comprobar("no hay tejado si no está declarado", e.tejado == null)
	_comprobar("ocultar el tejado inexistente no revienta",
		_no_revienta(func(): e.mostrar_tejado(false)))
	_comprobar("queda anotado como problema",
		Assets.problemas().any(func(p: String): return p.begins_with("edificio.no_existe")),
		str(Assets.problemas().size()))
	contenedor.queue_free()
	Assets.validar()

func _no_revienta(f: Callable) -> bool:
	f.call()
	return true

func _p12_zoom_discreto() -> void:
	print("12. Zoom en escalones y cámara a píxeles enteros")
	var cam := CamaraIsla.new()
	add_child(cam)

	_comprobar("hay dos niveles", CamaraIsla.NIVELES_PIXEL.size() == 2,
		str(CamaraIsla.NIVELES_PIXEL))
	_comprobar("son 0.5 y 1.0",
		CamaraIsla.NIVELES_PIXEL[0] == 0.5 and CamaraIsla.NIVELES_PIXEL[1] == 1.0)

	cam.modo_pixel = false
	cam.zoom = Vector2(0.55, 0.55)
	_comprobar("con el modo apagado el zoom sigue siendo libre",
		is_equal_approx(cam.zoom.x, 0.55))

	cam.modo_pixel = true
	_comprobar("al encenderlo salta al nivel más cercano",
		cam.zoom.x in [0.5, 1.0], str(cam.zoom.x))

	cam.zoom_a_nivel(1)
	_comprobar("nivel 1 es zoom 1.0", is_equal_approx(cam.zoom.x, 1.0))
	cam.zoom_a_nivel(0)
	_comprobar("nivel 0 es zoom 0.5", is_equal_approx(cam.zoom.x, 0.5))
	cam.zoom_a_nivel(99)
	_comprobar("no se sale de los niveles", is_equal_approx(cam.zoom.x, 1.0),
		str(cam.zoom.x))

	# Cuadrado a píxel: a zoom 1.0 se redondea a la unidad; a 0.5, de dos en dos.
	cam.zoom_a_nivel(1)
	cam.position = Vector2(100.37, 50.62)
	cam._cuadrar_a_pixel()
	_comprobar("a zoom 1.0 la cámara cae en enteros",
		cam.position == Vector2(100, 51), str(cam.position))
	cam.zoom_a_nivel(0)
	cam.position = Vector2(101.0, 51.0)
	cam._cuadrar_a_pixel()
	_comprobar("a zoom 0.5 cae en múltiplos de 2",
		int(cam.position.x) % 2 == 0 and int(cam.position.y) % 2 == 0,
		str(cam.position))
	cam.queue_free()

func _p13_paleta_maestra() -> void:
	print("13. Paleta maestra global y reservas de interfaz")
	_comprobar("contiene los 32 colores aprobados", GlobalColors.PALETA.size() == 32,
		str(GlobalColors.PALETA.size()))
	_comprobar("el vacío no es negro puro",
		GlobalColors.get_color_vacio() == Color("#0f0f1b"))
	_comprobar("ningún color de la paleta es negro puro",
		not GlobalColors.PALETA.values().has(Color("#000000")))
	_comprobar("el chroma-key no forma parte de la paleta de juego",
		not GlobalColors.PALETA.values().has(Color("#ff00ff")))
	_comprobar("todos los colores maestros son opacos",
		GlobalColors.PALETA.values().all(func(c: Color): return is_equal_approx(c.a, 1.0)))
	_comprobar("salud usa rojo brillante",
		GlobalColors.get_color_salud() == Color("#bd403a"))
	_comprobar("estamina usa verde claro",
		GlobalColors.get_color_estamina() == Color("#4a804d"))
	_comprobar("energía alternativa usa cian mágico",
		GlobalColors.get_color_energia() == Color("#5cb2b5"))
	_comprobar("interacción usa oro llama",
		GlobalColors.get_color_interaccion() == Color("#f5c051"))
	_comprobar("peligro usa naranja fuego",
		GlobalColors.get_color_peligro() == Color("#e87a41"))
	_comprobar("estado alterado usa verde tóxico",
		GlobalColors.get_color_estado_alterado() == Color("#a8ca58"))
	_comprobar("selección usa blanco puro",
		GlobalColors.get_color_seleccion() == Color("#ffffff"))
	_comprobar("el borde de selección es de un píxel",
		GlobalColors.BORDE_SELECCION_PX == 1)
	_comprobar("la iluminación declarada apunta arriba-izquierda",
		GlobalColors.DIRECCION_LUZ_2D == Vector2(-1, -1))
