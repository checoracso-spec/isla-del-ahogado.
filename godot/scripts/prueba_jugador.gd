extends Node
## Pruebas del jugador, la transitabilidad, la mochila y el guardado.
##
## Carga el mundo de verdad —no un simulacro— y lo empuja. Si estas pruebas
## pasan, el jugador existe, se mueve, choca con lo que debe y su estado
## sobrevive a guardar y cargar.
##
## Ejecutar:
##   Godot_..._console.exe --headless --path <carpeta godot> res://escenas/prueba_jugador.tscn

const RANURA_PRUEBA := 99
const ValidadorInteriorScript := preload("res://scripts/interiores/validador_interior.gd")

var fallos := 0
var pruebas := 0
var mundo: Mundo
var jugador: Jugador

func _ready() -> void:
	print("\n=== PRUEBAS DE JUGADOR ===\n")

	_p1_inventario_base()
	_p2_bolsa_y_almacen()

	await _cargar_mundo()
	if mundo == null:
		print("  FALLO no se pudo cargar el mundo")
		fallos += 1
	else:
		_p3_jugador_aparece()
		_p4_jugador_se_mueve()
		_p5_no_atraviesa()
		_p5b_huella()
		await _p6_reloj_sigue()
		_p7_guardar_y_cargar()
		_p8_guarda_la_posicion()
		_p9_entrar_y_salir()
		_p10_identidad()
		_p11_cofre()
		_p12_guardar_dentro()
		_p13_capas_y_validador()
		_p14_herreria()

	print("\n=== %d/%d correctas ===" % [pruebas - fallos, pruebas])
	get_tree().quit(1 if fallos > 0 else 0)

# ---------------------------------------------------------------------------

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	pruebas += 1
	if condicion:
		print("  OK    %s" % nombre)
	else:
		fallos += 1
		print("  FALLO %s   %s" % [nombre, detalle])

func _cargar_mundo() -> void:
	print("Cargando el mundo real...")
	var escena: PackedScene = load("res://escenas/mundo.tscn")
	mundo = escena.instantiate() as Mundo
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	jugador = mundo.jugador
	Reloj.pausado = true          # a partir de aquí, control manual

# ---------------------------------------------------------------------------

func _p1_inventario_base() -> void:
	print("1. Inventario base")
	var a := Inventario.new()
	_comprobar("empieza vacío", a.esta_vacio())
	a.anadir("ron", 5)
	_comprobar("añade 5", a.cantidad("ron") == 5, str(a.cantidad("ron")))
	_comprobar("no retira de más", not a.retirar("ron", 9))
	_comprobar("sigue habiendo 5", a.cantidad("ron") == 5)
	_comprobar("retira 3", a.retirar("ron", 3))
	_comprobar("quedan 2", a.cantidad("ron") == 2)

	var b := Inventario.new()
	var movidos := a.transferir_a(b, "ron", 5)
	_comprobar("transfiere sólo lo que hay", movidos == 2, str(movidos))
	_comprobar("origen vacío", a.cantidad("ron") == 0)
	_comprobar("destino con 2", b.cantidad("ron") == 2)

	# capacidad: el ron ocupa 1.5 por unidad, así que en 3.0 caben 2
	var c := Inventario.new()
	c.capacidad = 3.0
	var entraron := c.anadir("ron", 10)
	_comprobar("respeta la capacidad", entraron == 2, str(entraron))

func _p2_bolsa_y_almacen() -> void:
	print("2. La mochila y el almacén son cosas distintas")
	Almacen.vaciar()
	Bolsa.mochila.vaciar()
	Bolsa.oro = 0

	Almacen.anadir("tablon_tratado", 10)
	var sacados := Bolsa.retirar_del_almacen("tablon_tratado", 4)
	_comprobar("saca 4 del almacén", sacados == 4, str(sacados))
	_comprobar("al almacén le quedan 6", Almacen.cantidad("tablon_tratado") == 6,
		str(Almacen.cantidad("tablon_tratado")))
	_comprobar("la mochila lleva 4", Bolsa.mochila.cantidad("tablon_tratado") == 4)
	_comprobar("no se duplicó nada",
		Almacen.cantidad("tablon_tratado") + Bolsa.mochila.cantidad("tablon_tratado") == 10)

	Bolsa.depositar_en_almacen("tablon_tratado", 4)
	_comprobar("devuelve los 4", Almacen.cantidad("tablon_tratado") == 10)
	_comprobar("mochila vacía", Bolsa.mochila.cantidad("tablon_tratado") == 0)

	Bolsa.ingresar(100)
	_comprobar("no puede pagar de más", not Bolsa.pagar(150))
	_comprobar("el oro sigue intacto", Bolsa.oro == 100, str(Bolsa.oro))
	_comprobar("paga 40", Bolsa.pagar(40) and Bolsa.oro == 60, str(Bolsa.oro))

func _p3_jugador_aparece() -> void:
	print("3. El jugador aparece en sitio válido")
	_comprobar("existe", jugador != null)
	if jugador == null:
		return
	_comprobar("está en el árbol", jugador.is_inside_tree())
	_comprobar("tiene transitabilidad", jugador.transitable != null)
	_comprobar("aparece en casilla pisable",
		mundo.transitable.puede_pisar(jugador.casilla()), str(jugador.casilla()))
	_comprobar("la cámara le sigue",
		mundo._camara.objetivo == jugador and mundo._camara.modo == CamaraIsla.Modo.SEGUIR)
	var barbanegra: Pirata = null
	for tripulante in mundo.piratas:
		if tripulante.id_personaje == "barbanegra":
			barbanegra = tripulante
			break
	_comprobar("Barbanegra se monta desde la base de datos", barbanegra != null)
	_comprobar("la rutina separa casa y puesto de trabajo",
		barbanegra != null and barbanegra.casa != barbanegra.trabajo)
	var roster: Array[String] = mundo._personajes_con_puesto()
	_comprobar("el roster activo sale de PersonajeData", roster.size() == 8)
	_comprobar("el roster incluye a Anne Bonny desde datos", "anne_bonny" in roster)

func _p4_jugador_se_mueve() -> void:
	print("4. El jugador se mueve")
	var origen := jugador.pos_tile
	var movido := false
	# Prueba las cuatro diagonales: alguna tiene que estar despejada.
	for dir in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		jugador.colocar(origen)
		for i in 20:
			jugador.mover(dir, 0.05)
		if jugador.pos_tile.distance_to(origen) > 0.4:
			movido = true
			break
	_comprobar("se desplaza al empujarlo", movido,
		"de %s a %s" % [origen, jugador.pos_tile])
	_comprobar("el estado pasa a andar", jugador.estado == "andar", jugador.estado)
	jugador.mover(Vector2.ZERO, 0.05)
	_comprobar("y vuelve a idle al soltar", jugador.estado == "idle", jugador.estado)
	jugador.colocar(origen)

func _p5_no_atraviesa() -> void:
	print("5. No atraviesa agua ni edificios")

	# Orilla, no mar abierto: tiene que haber tierra al lado desde donde
	# empujar, o la prueba pasaría sin comprobar nada.
	var par := _bloqueada_con_vecino_libre()
	_comprobar("hay una orilla accesible", not par.is_empty())
	if not par.is_empty():
		var prohibida: Vector2i = par[0]
		var desde: Vector2i = par[1]
		_comprobar("la casilla del agua no es pisable",
			not mundo.transitable.puede_pisar(prohibida))
		_comprobar("empujando hacia el agua desde la orilla, no entra",
			_empujar_desde(desde, prohibida), "acabó en %s" % jugador.casilla())

	var edificio := Vector2i(-9999, -9999)
	for t in mundo.transitable.ocupadas:
		edificio = t
		break
	_comprobar("hay edificios ocupando casillas", edificio != Vector2i(-9999, -9999))
	if edificio != Vector2i(-9999, -9999):
		_comprobar("la casilla del edificio no es pisable",
			not mundo.transitable.puede_pisar(edificio))
		_comprobar("empujando hacia el edificio, no entra", _empujar_hacia(edificio),
			"acabó en %s" % jugador.casilla())

	# Y que sí pueda pisar lo que debe. Ojo: el centro exacto de la explanada
	# suele estar ocupado por un edificio, así que lo que importa es que quede
	# suelo libre por el que moverse entre las casas.
	var pisables := 0
	for t: Vector2i in mundo.isla.plaza:
		if mundo.transitable.puede_pisar(t):
			pisables += 1
	_comprobar("queda explanada pisable entre los edificios", pisables > 20,
		"sólo %d de %d casillas" % [pisables, mundo.isla.plaza.size()])

func _empujar_hacia(prohibida: Vector2i) -> bool:
	var desde := mundo.transitable.casilla_libre_cerca(prohibida, 8)
	if desde == prohibida:
		return false                      # sin hueco al lado la prueba no vale
	return _empujar_desde(desde, prohibida)

## Coloca al jugador en `desde` y empuja 60 veces contra `prohibida`.
## Devuelve true si NUNCA consiguió pisarla.
func _empujar_desde(desde: Vector2i, prohibida: Vector2i) -> bool:
	jugador.colocar(Vector2(desde) + Vector2(0.5, 0.5))
	var dir := (Vector2(prohibida) - Vector2(desde)).normalized()
	for i in 60:
		jugador.mover(dir, 0.05)
		if jugador.casilla() == prohibida:
			return false
	return true

func _p9_entrar_y_salir() -> void:
	print("9. Entrar en casa_a y volver a salir")

	_comprobar("el mundo creó puertas", mundo.puertas.size() > 0,
		str(mundo.puertas.size()))
	if mundo.puertas.is_empty():
		return
	var puerta: Puerta = mundo.puertas[0]
	_comprobar("la puerta lleva a un interior existente",
		BaseDeDatos.interior(puerta.interior_id) != null, puerta.interior_id)
	_comprobar("la puerta está en el grupo de interactuables",
		puerta.is_in_group(Interactuable.GRUPO))
	_comprobar("su texto es de entrar", puerta.texto_accion().begins_with("Entrar"),
		puerta.texto_accion())

	# Estado que NO debe cambiar al cruzar
	Bolsa.mochila.vaciar()
	Bolsa.mochila.anadir("ron", 2)
	Bolsa.oro = 321
	var dia_antes := Reloj.dia
	var fuera := Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5)
	var zoom_fuera := mundo.camara().zoom
	mundo.recibir_jugador(jugador, fuera)

	_comprobar("entra por la puerta", Interiores.entrar(puerta, jugador))
	_comprobar("el gestor sabe que estamos dentro", Interiores.dentro())
	_comprobar("el exterior se apaga", not mundo._objetos.visible)
	_comprobar("el jugador cuelga del interior",
		jugador.get_parent() == Interiores.activo.actores)
	_comprobar("cambió de transitabilidad",
		jugador.transitable is TransitableRejilla)
	_comprobar("aparece en la entrada del interior",
		jugador.pos_tile.distance_to(Interiores.activo.entrada()) < 0.6,
		"%s vs %s" % [jugador.pos_tile, Interiores.activo.entrada()])
	_comprobar("la zona pasó al interior", Ubicacion.zona == puerta.interior_id,
		Ubicacion.zona)
	_comprobar("el interior usa zoom de píxel entero",
		mundo.camara().zoom.is_equal_approx(Vector2.ONE), str(mundo.camara().zoom))
	_comprobar("el arte base del interior se elige por datos",
		Interiores.activo.definicion.asset_suelo == "interior.capitania_v1.suelo_madera")
	var arte_base := Interiores.activo.get_node_or_null("ArteBase")
	_comprobar("el interior monta su capa modular de arte", arte_base != null)
	_comprobar("suelo y paredes se montan como piezas reutilizables",
		arte_base != null and arte_base.get_child_count() == 90,
		str(arte_base.get_child_count() if arte_base != null else 0))
	_comprobar("escritorio, bancos y escalera usan sprites por datos",
		Interiores.activo.actores.get_node_or_null("Mueble_mesa_4_3") != null
		and Interiores.activo.actores.get_node_or_null("Mueble_banco_3_5") != null
		and Interiores.activo.actores.get_node_or_null("Mueble_escalera_7_3") != null)
	_comprobar("estantería y chimenea también usan sprites por datos",
		Interiores.activo.actores.get_node_or_null("Mueble_estanteria_2_1") != null
		and Interiores.activo.actores.get_node_or_null("Mueble_chimenea_7_1") != null)
	_comprobar("la segunda casilla del escritorio queda bloqueada",
		not jugador.transitable.puede_pisar(Vector2i(5, 3)))
	_comprobar("la segunda casilla de la escalera queda bloqueada",
		not jugador.transitable.puede_pisar(Vector2i(7, 4)))

	# La escalera es una transición de zona real, no sólo decoración. Ambas
	# plantas conservan el mismo edificio y el mismo retorno a la calle.
	var subida := Interiores.activo.actores.get_node_or_null(
		"Mueble_escalera_7_3") as Interactuable
	var sprite_subida := subida.get_child(0) as Sprite2D if subida != null \
		and subida.get_child_count() > 0 else null
	_comprobar("la escalera es interactuable", subida != null)
	_comprobar("la escalera anuncia Subir",
		subida != null and subida.texto_accion() == "Subir")
	var retorno_antes := Ubicacion.retorno
	var identidad_pb := Interiores.activo.identidad.instancia
	if subida != null:
		subida.interactuar(jugador)
	_comprobar("sube a la planta alta",
		Interiores.dentro()
		and Interiores.activo.definicion.id == "interior_capitania_pa",
		Ubicacion.zona)
	_comprobar("la planta alta no tiene salida directa a la calle",
		Interiores.activo.puerta_salida == null)
	_comprobar("la planta alta tiene identidad propia",
		Interiores.activo.identidad.instancia != identidad_pb,
		Interiores.activo.identidad.instancia)
	_comprobar("conserva el retorno exterior entre plantas",
		Ubicacion.retorno.is_equal_approx(retorno_antes), str(Ubicacion.retorno))
	_comprobar("la planta alta conserva arte y cofre",
		Interiores.activo.get_node_or_null("ArteBase") != null
		and Interiores.activo.cofres.size() == 1)
	var bajada := Interiores.activo.actores.get_node_or_null(
		"Mueble_escalera_7_3") as Interactuable
	_comprobar("la escalera superior anuncia Bajar",
		bajada != null and bajada.texto_accion() == "Bajar")
	var sprite_bajada := bajada.get_child(0) as Sprite2D if bajada != null \
		and bajada.get_child_count() > 0 else null
	_comprobar("subir y bajar usan siluetas diferentes",
		sprite_subida != null and sprite_bajada != null
		and sprite_subida.texture != sprite_bajada.texture)
	if bajada != null:
		bajada.interactuar(jugador)
	_comprobar("vuelve a la planta baja",
		Interiores.dentro()
		and Interiores.activo.definicion.id == "interior_capitania_pb",
		Ubicacion.zona)
	_comprobar("la planta baja recupera su identidad estable",
		Interiores.activo.identidad.instancia == identidad_pb,
		Interiores.activo.identidad.instancia)

	# Se puede caminar dentro, pero no atravesar la pared.
	var dentro_antes := jugador.pos_tile
	for i in 15:
		jugador.mover(Vector2(-1, -1), 0.05)     # hacia la esquina norte
	_comprobar("se puede caminar dentro", jugador.pos_tile != dentro_antes)
	_comprobar("no se sale por la pared",
		jugador.transitable.puede_pisar(jugador.casilla()),
		str(jugador.casilla()))
	var r := (jugador.transitable as TransitableRejilla).limites()
	_comprobar("sigue dentro de los límites del cuarto",
		jugador.casilla().x >= 0 and jugador.casilla().y >= 0
		and jugador.casilla().x < r.size.x and jugador.casilla().y < r.size.y,
		str(jugador.casilla()))

	# La puerta de salida existe y dice lo suyo
	var salida: Puerta = Interiores.activo.puerta_salida
	_comprobar("hay puerta de salida", salida != null)
	_comprobar("su texto es Salir", salida != null and salida.texto_accion() == "Salir")

	_comprobar("sale del interior", Interiores.salir(jugador))
	_comprobar("el gestor sabe que estamos fuera", not Interiores.dentro())
	_comprobar("el exterior vuelve a encenderse", mundo._objetos.visible)
	_comprobar("el jugador vuelve a colgar del exterior",
		jugador.get_parent() == mundo._objetos)
	_comprobar("vuelve a la casilla de la puerta",
		jugador.pos_tile.distance_to(fuera) < 0.6,
		"%s vs %s" % [jugador.pos_tile, fuera])
	_comprobar("la zona vuelve al exterior", Ubicacion.en_exterior(), Ubicacion.zona)
	_comprobar("al salir recupera el zoom exterior",
		mundo.camara().zoom.is_equal_approx(zoom_fuera), str(mundo.camara().zoom))

	_comprobar("la mochila no se tocó", Bolsa.mochila.cantidad("ron") == 2)
	_comprobar("el oro no se tocó", Bolsa.oro == 321, str(Bolsa.oro))
	_comprobar("el día no se tocó", Reloj.dia == dia_antes)

func _p10_identidad() -> void:
	print("10. Identidad de instancia")

	var a := Entidades.identificar("edificio", "taberna", "isla:taberna@10,10")
	var b := Entidades.identificar("edificio", "taberna", "isla:taberna@40,40")
	_comprobar("dos tabernas comparten definición", a.definicion == b.definicion)
	_comprobar("pero tienen instancias distintas", a.instancia != b.instancia,
		"%s / %s" % [a.instancia, b.instancia])
	_comprobar("el instance_id NO es el definition_id",
		a.instancia != a.definicion and not a.instancia.begins_with("taberna"))
	var otra_vez := Entidades.identificar("edificio", "taberna", "isla:taberna@10,10")
	_comprobar("la misma clave devuelve el mismo id", otra_vez.instancia == a.instancia)
	_comprobar("identificar_nueva siempre acuña una nueva",
		Entidades.identificar_nueva("objeto", "cofre_oxidado").instancia
			!= Entidades.identificar_nueva("objeto", "cofre_oxidado").instancia)

	# Los del mundo real
	var edificio: EdificioVisual = mundo.visuales.values()[0]
	_comprobar("los edificios del mapa tienen identidad", edificio.identidad != null)
	_comprobar("y su instancia no es su definición",
		edificio.identidad != null
			and edificio.identidad.instancia != edificio.identidad.definicion)
	var puerta: Puerta = mundo.puertas[0]
	_comprobar("las puertas tienen identidad", puerta.identidad != null)
	_comprobar("la puerta apunta a la instancia del edificio, no al tipo",
		puerta.edificio_instancia.begins_with("edificio_"), puerta.edificio_instancia)
	_comprobar("cada puerta tiene una instancia distinta",
		mundo.puertas.size() < 2
			or mundo.puertas[0].identidad.instancia != mundo.puertas[1].identidad.instancia)

func _p11_cofre() -> void:
	print("11. El cofre")
	var puerta: Puerta = mundo.puertas[0]
	Bolsa.mochila.vaciar()
	mundo.recibir_jugador(jugador, Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5))
	Interiores.entrar(puerta, jugador)

	_comprobar("el interior tiene identidad propia", Interiores.activo.identidad != null)
	_comprobar("hay un cofre dentro", Interiores.activo.cofres.size() == 1,
		str(Interiores.activo.cofres.size()))
	if Interiores.activo.cofres.is_empty():
		return
	var cofre: Cofre = Interiores.activo.cofres[0]
	_comprobar("el cofre tiene identidad", cofre.identidad != null)
	_comprobar("el cofre usa Inventario", cofre.inventario() is Inventario)
	_comprobar("empieza con 3 rones", cofre.inventario().cantidad("ron") == 3,
		str(cofre.inventario().cantidad("ron")))
	_comprobar("su texto es Abrir cofre", cofre.texto_accion() == "Abrir cofre")
	var visual_cofre := cofre.get_node_or_null("Visual") as Sprite2D
	_comprobar("el cofre tiene sprite artístico", visual_cofre != null)
	var textura_cerrada: Texture2D = visual_cofre.texture if visual_cofre != null else null
	cofre.interactuar(jugador)
	_comprobar("al interactuar cambia al sprite abierto",
		visual_cofre != null and visual_cofre.texture != textura_cerrada)

	# Tomar el ron: sube la mochila, baja el cofre, no se duplica nada.
	var instancia_cofre := cofre.identidad.instancia
	cofre.inventario().transferir_a(Bolsa.mochila, "ron", 3)
	_comprobar("el ron pasa a la mochila", Bolsa.mochila.cantidad("ron") == 3,
		str(Bolsa.mochila.cantidad("ron")))
	_comprobar("el cofre se queda vacío", cofre.inventario().esta_vacio())
	_comprobar("no se duplicó",
		Bolsa.mochila.cantidad("ron") + cofre.inventario().cantidad("ron") == 3)
	_comprobar("ahora dice que está vacío", cofre.texto_accion() == "Cofre vacío")

	# Salir y volver a entrar NO debe reponerlo.
	Interiores.salir(jugador)
	Interiores.entrar(puerta, jugador)
	var cofre2: Cofre = Interiores.activo.cofres[0]
	_comprobar("al reentrar es el mismo cofre",
		cofre2.identidad.instancia == instancia_cofre)
	_comprobar("y NO se ha repuesto el ron", cofre2.inventario().esta_vacio(),
		str(cofre2.inventario().cantidad("ron")))
	_comprobar("la mochila conserva su ron", Bolsa.mochila.cantidad("ron") == 3)
	Interiores.salir(jugador)

func _p12_guardar_dentro() -> void:
	print("12. Guardar dentro del interior")
	var puerta: Puerta = mundo.puertas[0]
	var fuera := Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5)
	mundo.recibir_jugador(jugador, fuera)
	Interiores.entrar(puerta, jugador)

	# Se mueve dentro para que la posición guardada no sea la de la entrada.
	for i in 12:
		jugador.mover(Vector2(-1, -1), 0.05)
	var dentro_pos := jugador.pos_tile
	Ubicacion.anotar(dentro_pos, jugador.direccion)
	Bolsa.oro = 555
	Reloj.dia = 9
	var ron_antes := Bolsa.mochila.cantidad("ron")

	_comprobar("guarda estando dentro", Guardado.guardar(RANURA_PRUEBA))

	# Se simula reabrir el juego: fuera, sin nada, y se carga.
	Interiores.salir(jugador)
	Bolsa.oro = 0
	Reloj.dia = 1
	_comprobar("carga la partida", Guardado.cargar(RANURA_PRUEBA))

	_comprobar("reaparece DENTRO del interior", Interiores.dentro())
	_comprobar("en la zona correcta", Ubicacion.zona == puerta.interior_id,
		Ubicacion.zona)
	_comprobar("y en la casilla donde guardó",
		jugador.pos_tile.distance_to(dentro_pos) < 0.6,
		"%s vs %s" % [jugador.pos_tile, dentro_pos])
	_comprobar("el oro volvió", Bolsa.oro == 555, str(Bolsa.oro))
	_comprobar("el día volvió", Reloj.dia == 9, str(Reloj.dia))
	_comprobar("la mochila intacta", Bolsa.mochila.cantidad("ron") == ron_antes)

	if Interiores.dentro():
		var cofre: Cofre = Interiores.activo.cofres[0]
		_comprobar("el cofre sigue vacío tras cargar", cofre.inventario().esta_vacio(),
			str(cofre.inventario().cantidad("ron")))

	_comprobar("se puede salir tras cargar dentro", Interiores.salir(jugador))
	_comprobar("y sale por la puerta correcta",
		jugador.pos_tile.distance_to(fuera) < 1.2,
		"%s vs %s" % [jugador.pos_tile, fuera])
	_comprobar("de vuelta en el exterior", Ubicacion.en_exterior())

	Guardado.borrar(RANURA_PRUEBA)

func _p13_capas_y_validador() -> void:
	print("13. Capas visuales y validador genérico de interiores")
	var def := InteriorDefinicion.desde_dic({
		"id": "prueba_capas", "nombre": "Prueba de capas",
		"ancho": 6, "alto": 6, "entrada": Vector2i(2, 4),
		"asset_suelo": "interior.capitania_v1.suelo_madera",
		"asset_muro_norte": "interior.capitania_v1.muro_norte",
		"asset_muro_oeste": "interior.capitania_v1.muro_oeste",
		"muebles": [
			{"tipo": "alfombra", "casilla": Vector2i(2, 3), "solido": false,
				"capa_visual": "suelo", "asset": "mueble.comun.banco_madera"},
			{"tipo": "mapa", "casilla": Vector2i(0, 2), "solido": false,
				"capa_visual": "pared", "asset": "mueble.capitania.estanteria_nautica"},
			{"tipo": "mesa", "casilla": Vector2i(2, 2), "solido": true,
				"huella": Vector2i(2, 1), "capa_visual": "mundo",
				"asset": "mueble.capitania.escritorio"},
			{"tipo": "chispa", "casilla": Vector2i(3, 3), "solido": false,
				"capa_visual": "efectos", "asset": "objeto.farol"},
			{"tipo": "escalera", "casilla": Vector2i(4, 1), "solido": true,
				"huella": Vector2i(1, 2), "capa_visual": "mundo",
				"asset": "mueble.comun.escalera_madera",
				"destino_zona": "interior_capitania_pa"},
		]
	})
	var escena := InteriorEscena.new()
	add_child(escena)
	escena.construir(def, Vector2i.ZERO, "prueba", "prueba_0001")
	var arte := escena.get_node_or_null("ArteBase")
	_comprobar("crea contenedores separados de suelo y pared",
		arte != null
		and arte.get_node_or_null("DecoracionSuelo") != null
		and arte.get_node_or_null("DecoracionPared") != null)
	_comprobar("la decoración de suelo no entra en Actores",
		escena.get_node_or_null("ArteBase/DecoracionSuelo/Mueble_alfombra_2_3") != null
		and escena.actores.get_node_or_null("Mueble_alfombra_2_3") == null)
	_comprobar("la decoración de pared no entra en Actores",
		escena.get_node_or_null("ArteBase/DecoracionPared/Mueble_mapa_0_2") != null
		and escena.actores.get_node_or_null("Mueble_mapa_0_2") == null)
	_comprobar("los muebles siguen ordenados con los actores",
		escena.actores.get_node_or_null("Mueble_mesa_2_2") != null)
	_comprobar("los efectos tienen su contenedor superior",
		escena.get_node_or_null("Efectos/Mueble_chispa_3_3") != null
		and escena.get_children().find(escena.get_node("Efectos"))
			> escena.get_children().find(escena.actores))
	var mesa := escena.actores.get_node_or_null("Mueble_mesa_2_2") as Node2D
	_comprobar("una huella 2×1 se ancla en el apoyo de su última casilla",
		mesa != null and mesa.position == Iso.apoyo(3, 2),
		str(mesa.position if mesa != null else Vector2.INF))
	var escalera := escena.actores.get_node_or_null("Mueble_escalera_4_1") as Node2D
	_comprobar("una huella 1×2 se ancla en el apoyo de su última casilla",
		escalera != null and escalera.position == Iso.apoyo(4, 2),
		str(escalera.position if escalera != null else Vector2.INF))
	var chispa := escena.get_node_or_null("Efectos/Mueble_chispa_3_3") as Node2D
	_comprobar("una huella 1×1 conserva el centro del rombo",
		chispa != null and chispa.position == Iso.centro_v(Vector2i(3, 3)),
		str(chispa.position if chispa != null else Vector2.INF))
	_comprobar("la puerta de salida pertenece a la capa de suelo",
		escena.puerta_salida != null
		and escena.puerta_salida.get_parent() == escena.get_node("ArteBase/DecoracionSuelo"))
	escena.queue_free()

	var sin_arte := InteriorDefinicion.desde_dic({
		"id": "prueba_respaldo", "ancho": 5, "alto": 5,
		"entrada": Vector2i(2, 3),
		"muebles": [{"tipo": "mapa", "casilla": Vector2i(0, 2),
			"solido": false, "capa_visual": "pared",
			"asset": "mueble.capitania.estanteria_nautica"}]
	})
	var escena_sin_arte := InteriorEscena.new()
	add_child(escena_sin_arte)
	escena_sin_arte.construir(sin_arte, Vector2i.ZERO, "prueba", "prueba_0002")
	_comprobar("sin arte modular la decoración de pared cae en Actores",
		escena_sin_arte.get_node_or_null("ArteBase") == null
		and escena_sin_arte.actores.get_node_or_null("Mueble_mapa_0_2") != null
		and escena_sin_arte.get_children().find(escena_sin_arte.puerta_salida)
			< escena_sin_arte.get_children().find(escena_sin_arte.actores))
	escena_sin_arte.queue_free()

	var problemas_existentes := PackedStringArray()
	for datos in BaseDeDatos.TABLA_INTERIORES:
		var interior := BaseDeDatos.interior(str(datos.get("id", "")))
		problemas_existentes.append_array(ValidadorInteriorScript.validar(interior))
	_comprobar("todos los interiores actuales cumplen las reglas genéricas",
		problemas_existentes.is_empty(), " | ".join(problemas_existentes))

	var solape := InteriorDefinicion.desde_dic({
		"id": "mal_solape", "ancho": 6, "alto": 6, "entrada": Vector2i(2, 4),
		"muebles": [
			{"tipo": "a", "casilla": Vector2i(2, 2), "solido": true},
			{"tipo": "b", "casilla": Vector2i(2, 2), "solido": true},
		]
	})
	var errores_solape: PackedStringArray = ValidadorInteriorScript.validar(solape)
	_comprobar("detecta muebles solapados",
		_alguno_contiene(errores_solape, "solapan"),
		" | ".join(errores_solape))

	var aislado := InteriorDefinicion.desde_dic({
		"id": "mal_aislado", "ancho": 6, "alto": 6, "entrada": Vector2i(1, 1),
		"muebles": [
			{"tipo": "muro", "casilla": Vector2i(2, 1), "huella": Vector2i(1, 4),
				"solido": true},
		]
	})
	var errores_aislado: PackedStringArray = ValidadorInteriorScript.validar(aislado)
	_comprobar("detecta zonas libres incomunicadas",
		_alguno_contiene(errores_aislado, "accesibles"),
		" | ".join(errores_aislado))

	var asset_malo := InteriorDefinicion.desde_dic({
		"id": "mal_asset", "ancho": 5, "alto": 5, "entrada": Vector2i(1, 2),
		"muebles": [{"tipo": "fantasma", "casilla": Vector2i(2, 2),
			"solido": false, "capa_visual": "limbo", "asset": "no.existe"}]
	})
	var errores_asset: PackedStringArray = ValidadorInteriorScript.validar(asset_malo)
	_comprobar("detecta capas visuales inválidas",
		_alguno_contiene(errores_asset, "capa_visual"))
	_comprobar("detecta claves de asset inexistentes",
		_alguno_contiene(errores_asset, "asset inexistente"))

	var no_solido_fuera := InteriorDefinicion.desde_dic({
		"id": "mal_decor_fuera", "ancho": 5, "alto": 5,
		"entrada": Vector2i(2, 3),
		"muebles": [{"tipo": "alfombra", "casilla": Vector2i(0, 0),
			"solido": false, "capa_visual": "suelo"}]
	})
	var errores_fuera := ValidadorInteriorScript.validar(no_solido_fuera)
	_comprobar("detecta decoración no sólida fuera del interior",
		_alguno_contiene(errores_fuera, "fuera del interior"),
		" | ".join(errores_fuera))

	var no_solido_fuera_mapa := InteriorDefinicion.desde_dic({
		"id": "mal_decor_fuera_mapa", "ancho": 5, "alto": 5,
		"entrada": Vector2i(2, 3),
		"muebles": [{"tipo": "mapa", "casilla": Vector2i(5, 2),
			"solido": false, "capa_visual": "pared"}]
	})
	var errores_fuera_mapa := ValidadorInteriorScript.validar(no_solido_fuera_mapa)
	_comprobar("detecta decoración no sólida fuera de la rejilla completa",
		_alguno_contiene(errores_fuera_mapa, "fuera del interior"),
		" | ".join(errores_fuera_mapa))

	var no_solido_entrada := InteriorDefinicion.desde_dic({
		"id": "mal_decor_entrada", "ancho": 5, "alto": 5,
		"entrada": Vector2i(2, 3),
		"muebles": [{"tipo": "alfombra", "casilla": Vector2i(2, 3),
			"solido": false, "capa_visual": "suelo"}]
	})
	var errores_entrada := ValidadorInteriorScript.validar(no_solido_entrada)
	_comprobar("detecta decoración no sólida sobre la entrada",
		_alguno_contiene(errores_entrada, "ocupa la entrada"),
		" | ".join(errores_entrada))

	var no_solido_solapado := InteriorDefinicion.desde_dic({
		"id": "mal_decor_solapado", "ancho": 6, "alto": 6,
		"entrada": Vector2i(2, 4),
		"muebles": [
			{"tipo": "mesa", "casilla": Vector2i(2, 2), "solido": true},
			{"tipo": "alfombra", "casilla": Vector2i(2, 2), "solido": false,
				"capa_visual": "suelo"},
		]
	})
	var errores_decor_solapado := ValidadorInteriorScript.validar(no_solido_solapado)
	_comprobar("detecta decoración no sólida solapada con un sólido",
		_alguno_contiene(errores_decor_solapado, "se solapa con mueble"),
		" | ".join(errores_decor_solapado))

	var cofre_inexistente := InteriorDefinicion.desde_dic({
		"id": "mal_cofre", "ancho": 5, "alto": 5,
		"entrada": Vector2i(2, 3),
		"muebles": [{"tipo": "cofre", "casilla": Vector2i(1, 1),
			"solido": true, "definicion": "cofre_que_no_existe"}]
	})
	var errores_cofre := ValidadorInteriorScript.validar(cofre_inexistente)
	_comprobar("detecta la definición inexistente de un cofre",
		_alguno_contiene(errores_cofre, "definición inexistente"),
		" | ".join(errores_cofre))

	var solido_en_pared := InteriorDefinicion.desde_dic({
		"id": "mal_solido_capa", "ancho": 5, "alto": 5,
		"entrada": Vector2i(2, 3),
		"muebles": [{"tipo": "mesa", "casilla": Vector2i(1, 1),
			"solido": true, "capa_visual": "pared"}]
	})
	var errores_solido_capa := ValidadorInteriorScript.validar(solido_en_pared)
	_comprobar("exige capa mundo para los muebles sólidos",
		_alguno_contiene(errores_solido_capa, "debe usar capa_visual 'mundo'"),
		" | ".join(errores_solido_capa))

func _alguno_contiene(lista: PackedStringArray, fragmento: String) -> bool:
	for texto in lista:
		if fragmento in texto:
			return true
	return false

func _p14_herreria() -> void:
	print("14. Vertical slice de la Herrería Calavera y Ancla")
	var puerta: Puerta = null
	for candidata in mundo.puertas:
		if candidata.edificio_definicion == "herreria":
			puerta = candidata
			break
	_comprobar("la Herrería conserva una puerta exterior", puerta != null)
	if puerta == null:
		return
	_comprobar("la Herrería apunta a su interior especializado",
		puerta.interior_id == "interior_herreria_pb", puerta.interior_id)
	var datos_edificio := BaseDeDatos.edificio("herreria")
	_comprobar("el exterior artístico sigue fuera de alcance",
		datos_edificio != null and datos_edificio.asset_exterior == "")
	_comprobar("recetas y rol logístico permanecen intactos",
		datos_edificio != null and datos_edificio.rol == "produccion"
		and datos_edificio.recetas.size() == 4)

	var identidades_antes := {}
	for otra in mundo.puertas:
		if otra.edificio_definicion != "herreria":
			identidades_antes[otra.edificio_instancia] = otra.identidad.instancia
	var fuera := Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5)
	mundo.recibir_jugador(jugador, fuera)
	_comprobar("se puede entrar en la Herrería", Interiores.entrar(puerta, jugador))
	if not Interiores.dentro():
		return
	_comprobar("la zona activa es la Herrería",
		Interiores.activo.definicion.id == "interior_herreria_pb",
		Interiores.activo.definicion.id)
	_comprobar("usa una rejilla 10×8",
		Interiores.activo.limites().size == Vector2i(10, 8),
		str(Interiores.activo.limites()))

	var transitables := 0
	for y in range(1, 7):
		for x in range(1, 9):
			if jugador.transitable.puede_pisar(Vector2i(x, y)):
				transitables += 1
	_comprobar("hay exactamente 35 casillas interiores transitables",
		transitables == 35, str(transitables))
	var problemas: PackedStringArray = ValidadorInteriorScript.validar(
		Interiores.activo.definicion)
	_comprobar("el plano supera el validador genérico", problemas.is_empty(),
		" | ".join(problemas))

	var arte := Interiores.activo.get_node_or_null("ArteBase")
	_comprobar("ventanas y panoplia están realmente en la pared",
		arte != null
		and arte.get_node_or_null("DecoracionPared/Mueble_ventana_3_0") != null
		and arte.get_node_or_null("DecoracionPared/Mueble_panoplia_0_4") != null)
	_comprobar("ninguna ventana quedó dentro de Actores",
		Interiores.activo.actores.get_node_or_null("Mueble_ventana_3_0") == null
		and Interiores.activo.actores.get_node_or_null("Mueble_ventana_0_2") == null)
	_comprobar("fragua, yunque y banco sí respetan el orden por Y",
		Interiores.activo.actores.get_node_or_null("Mueble_fragua_1_1") != null
		and Interiores.activo.actores.get_node_or_null("Mueble_yunque_4_2") != null
		and Interiores.activo.actores.get_node_or_null("Mueble_banco_trabajo_6_1") != null)
	_comprobar("las huellas anchas bloquean sus dos casillas",
		not jugador.transitable.puede_pisar(Vector2i(2, 1))
		and not jugador.transitable.puede_pisar(Vector2i(7, 1))
		and not jugador.transitable.puede_pisar(Vector2i(4, 4)))
	_comprobar("el cofre contiene herramientas y carbón",
		Interiores.activo.cofres.size() == 1
		and Interiores.activo.cofres[0].inventario().cantidad("herramienta") == 1
		and Interiores.activo.cofres[0].inventario().cantidad("carbon") == 4)

	var guardada := Vector2(5.5, 5.5)
	jugador.colocar(guardada)
	Ubicacion.anotar(jugador.pos_tile, jugador.direccion)
	_comprobar("guarda desde la Herrería", Guardado.guardar(RANURA_PRUEBA))
	_comprobar("sale antes de simular la carga", Interiores.salir(jugador))
	_comprobar("carga de nuevo la partida", Guardado.cargar(RANURA_PRUEBA))
	_comprobar("reabre exactamente la Herrería",
		Interiores.dentro()
		and Interiores.activo.definicion.id == "interior_herreria_pb")
	_comprobar("recupera la casilla guardada",
		jugador.pos_tile.distance_to(guardada) < 0.6, str(jugador.pos_tile))
	if Interiores.dentro():
		_comprobar("sale por la misma puerta tras cargar", Interiores.salir(jugador)
			and jugador.pos_tile.distance_to(fuera) < 1.2, str(jugador.pos_tile))
	Guardado.borrar(RANURA_PRUEBA)

	var identidades_iguales := true
	for otra in mundo.puertas:
		if otra.edificio_definicion == "herreria":
			continue
		if identidades_antes.get(otra.edificio_instancia, "") != otra.identidad.instancia:
			identidades_iguales = false
	_comprobar("ningún otro edificio cambió de identidad", identidades_iguales)

## Una casilla bloqueada que tenga suelo pisable al lado. Es la que interesa:
## la primera casilla bloqueada del mapa es mar abierto en una esquina, y
## empujar contra ella no demuestra nada porque no se puede llegar.
func _bloqueada_con_vecino_libre() -> Array:
	for y in range(1, mundo.ALTO - 1):
		for x in range(1, mundo.ANCHO - 1):
			var t := Vector2i(x, y)
			if mundo.transitable.puede_pisar(t):
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var vecina: Vector2i = t + d
				if mundo.transitable.puede_pisar(vecina):
					return [t, vecina]
	return []

func _buscar_casilla(criterio: Callable) -> Vector2i:
	for y in range(mundo.ALTO):
		for x in range(mundo.ANCHO):
			var t := Vector2i(x, y)
			if criterio.call(t):
				return t
	return Vector2i(-9999, -9999)

func _p5b_huella() -> void:
	print("5b. Huella rectangular")
	var pequena := Huella.cuadrada(0.5)
	var grande := Huella.cuadrada(2.0)
	var alargada := Huella.new(2.0, 1.0)

	_comprobar("una huella pequeña cubre 1 casilla",
		pequena.casillas_bajo(Vector2(5.5, 5.5)).size() == 1,
		str(pequena.casillas_bajo(Vector2(5.5, 5.5))))
	_comprobar("una de 2×2 cubre 9 casillas al centrarla en un borde",
		grande.casillas_bajo(Vector2(5.5, 5.5)).size() == 9,
		str(grande.casillas_bajo(Vector2(5.5, 5.5)).size()))
	_comprobar("una de 2×1 no es cuadrada",
		alargada.casillas_bajo(Vector2(5.5, 5.5)).size()
			!= Huella.new(1.0, 2.0).casillas_bajo(Vector2(5.5, 5.5)).size()
		or alargada.ancho != alargada.alto)

	# Lo que el sistema viejo no sabía hacer: justo al lado de un obstáculo,
	# una huella pequeña cabe y una grande no.
	var par := _bloqueada_con_vecino_libre()
	_comprobar("hay una orilla donde probar", not par.is_empty())
	if not par.is_empty():
		var centro := Vector2(par[1] as Vector2i) + Vector2(0.5, 0.5)
		_comprobar("el jugador cabe junto a un obstáculo",
			mundo.transitable.cabe_en(centro, pequena), str(par[1]))
		_comprobar("un actor grande NO cabe en el mismo sitio",
			not mundo.transitable.cabe_en(centro, grande))

func _p6_reloj_sigue() -> void:
	print("6. El reloj sigue corriendo")
	Reloj.pausado = false
	var antes := Reloj.hora
	await get_tree().create_timer(0.4).timeout
	var despues := Reloj.hora
	Reloj.pausado = true
	_comprobar("la hora avanza", despues > antes, "%f -> %f" % [antes, despues])

func _p7_guardar_y_cargar() -> void:
	print("7. Guardar y cargar")
	Bolsa.mochila.vaciar()
	Bolsa.mochila.anadir("ron", 3)
	Bolsa.mochila.anadir("mapa_tesoro", 1)
	Bolsa.oro = 777
	Bolsa.salud = 62.0
	Bolsa.energia = 41.0
	Reloj.dia = 5
	Reloj.hora = 14.25

	_comprobar("guarda sin error", Guardado.guardar(RANURA_PRUEBA))
	_comprobar("el archivo existe", Guardado.existe(RANURA_PRUEBA))

	# Se destroza todo a propósito
	Bolsa.mochila.vaciar()
	Bolsa.oro = 0
	Bolsa.salud = 100.0
	Bolsa.energia = 100.0
	Reloj.dia = 1
	Reloj.hora = 7.5

	_comprobar("carga sin error", Guardado.cargar(RANURA_PRUEBA))
	_comprobar("vuelve el oro", Bolsa.oro == 777, str(Bolsa.oro))
	_comprobar("vuelve el ron", Bolsa.mochila.cantidad("ron") == 3)
	_comprobar("vuelve el mapa", Bolsa.mochila.cantidad("mapa_tesoro") == 1)
	_comprobar("vuelve la salud", is_equal_approx(Bolsa.salud, 62.0), str(Bolsa.salud))
	_comprobar("vuelve la energía", is_equal_approx(Bolsa.energia, 41.0), str(Bolsa.energia))
	_comprobar("vuelve el día", Reloj.dia == 5, str(Reloj.dia))
	_comprobar("vuelve la hora", is_equal_approx(Reloj.hora, 14.25), str(Reloj.hora))

	_comprobar("las secciones previstas están registradas",
		"jugador" in Guardado.secciones_activas() and "reloj" in Guardado.secciones_activas(),
		str(Guardado.secciones_activas()))

	Guardado.borrar(RANURA_PRUEBA)
	_comprobar("se puede borrar la partida", not Guardado.existe(RANURA_PRUEBA))

func _p8_guarda_la_posicion() -> void:
	print("8. La posición del jugador sobrevive a guardar y cargar")

	# Punto A: donde está ahora, que sabemos que es pisable.
	var a := jugador.pos_tile
	Ubicacion.anotar(a, jugador.direccion)
	_comprobar("guarda con el jugador en A", Guardado.guardar(RANURA_PRUEBA))

	# Punto B: otro sitio pisable, lejos.
	var b := Vector2.ZERO
	for t: Vector2i in mundo.isla.plaza:
		var candidata := Vector2(t) + Vector2(0.5, 0.5)
		if candidata.distance_to(a) > 6.0 and mundo.transitable.cabe_en(candidata, jugador.huella):
			b = candidata
			break
	_comprobar("hay un punto B lejano y pisable", b != Vector2.ZERO)
	if b == Vector2.ZERO:
		return

	jugador.colocar(b)
	Ubicacion.anotar(b, jugador.direccion)
	_comprobar("el jugador se movió a B", jugador.pos_tile.distance_to(a) > 6.0,
		"%s vs %s" % [jugador.pos_tile, a])

	_comprobar("carga la partida", Guardado.cargar(RANURA_PRUEBA))
	_comprobar("el jugador vuelve EXACTAMENTE a A",
		jugador.pos_tile.distance_to(a) < 0.01,
		"esperaba %s y está en %s" % [a, jugador.pos_tile])
	_comprobar("la ubicación guardada también vuelve a A",
		Ubicacion.pos.distance_to(a) < 0.01, str(Ubicacion.pos))
	_comprobar("la zona es el exterior", Ubicacion.en_exterior(), Ubicacion.zona)
	_comprobar("la posición NO la guarda Bolsa",
		not Bolsa._serializar().has("pos") and not Bolsa._serializar().has("pos_tile"))

	Guardado.borrar(RANURA_PRUEBA)
