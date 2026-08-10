class_name Mundo
extends Node2D
const PanelCrafteoScript := preload("res://scripts/ui/panel_crafteo.gd")
const PanelMochilaScript := preload("res://scripts/ui/panel_mochila.gd")
const PanelMercadoScript := preload("res://scripts/ui/panel_mercado.gd")
const PanelTabernaScript := preload("res://scripts/ui/panel_taberna.gd")
const PanelMuelleScript := preload("res://scripts/ui/panel_muelle.gd")
const PuestoMuelleScript := preload("res://scripts/interiores/puesto_muelle.gd")
const FuenteRecursoScript := preload("res://scripts/mapa/fuente_recurso.gd")
const ParcelaCultivoScript := preload("res://scripts/mapa/parcela_cultivo.gd")
const ZonaExteriorScript := preload("res://scripts/mapa/zona_exterior.gd")
const AnimalScript := preload("res://scripts/mapa/animal.gd")
## La isla en pantalla, enchufada a la logística que ya existía.
##
## Aquí no se inventa ninguna regla nueva: los edificios humean porque su
## EstacionTrabajo está produciendo, se ponen en rojo porque Almacen no tiene
## su insumo, y los piratas se van a la taberna porque Reloj dice que anochece.
## El mapa es una VISTA de los sistemas, no una copia de ellos.

const ANCHO := 60
const ALTO := 60
const SEMILLA := 20260808

## Qué render usa cada edificio y en qué giro.
##
## OJO con los ángulos: cada carpeta trae 8 PNG, pero NO son 8 rotaciones.
## Son 4 rotaciones (00–03) y las mismas 4 CON NIEVE (04–07). Usar un 04+ deja
## el edificio con el tejado blanco en mitad del Caribe. Sólo 00–03.
const GIROS_VALIDOS := 4

const REPARTO := {
	"taberna":       { "modelo": "casa_b",    "angulo": 0 },
	"herreria":      { "modelo": "casa_a",    "angulo": 2 },
	"muelle_grua":   { "modelo": "cobertizo", "angulo": 2 },
	"mercado":       { "modelo": "cobertizo", "angulo": 1 },
	"alcaldia":      { "modelo": "caseron",   "angulo": 0 },
	"capilla":       { "modelo": "casa_c",    "angulo": 0 },
	"capitania":     { "modelo": "casa_a",    "angulo": 1 },
	"cabana_capitan":{ "modelo": "casa_c",    "angulo": 3 },
	"faro":          { "modelo": "casa_a",    "angulo": 3 },
	"corrales":      { "modelo": "cobertizo", "angulo": 3 },
}

## Dónde vive cada corsario reclutado.
const PUESTOS := {
	"calico_jack": "taberna", "barbanegra": "herreria", "anne_bonny": "capitania",
	"dientes_oro": "corrales", "garfio_cobre": "muelle_grua", "ojo_vidrio": "faro",
	"black_sam": "taberna", "henry_morgan": "mercado",
}

var isla: GeneradorIsla
var constructor: ConstructorTileset
## Quién puede pisar qué en el exterior. Antes la ocupación de los edificios se
## calculaba al colocarlos y se tiraba; ahora se conserva aquí y es lo que
## impide que el jugador atraviese las casas.
var transitable: TransitableIsla
var zona_exterior: Zona
var jugador: Jugador
var casillas_edificio: Dictionary = {}       ## id_edificio -> Vector2i
var visuales: Dictionary = {}                ## id_edificio -> EdificioVisual
var estaciones: Array[EstacionTrabajo] = []
var piratas: Array[Pirata] = []
var puertas: Array[Puerta] = []
var fuentes_recurso: Array = []
var parcelas_cultivo: Array = []
var animales: Array = []

var _terreno: TileMapLayer
var _suelo_pueblo: TileMapLayer
var _objetos: Node2D
var _camara: CamaraIsla
var _tinte: CanvasModulate
var _hud: Control
var _bajo_raton: EdificioVisual = null

func _ready() -> void:
	RenderingServer.set_default_clear_color(GlobalColors.PALETA["azul_noche"])
	_construir_mundo()
	_montar_logistica()
	_montar_hud()
	_conectar()
	_apuntar(_resumen_fuentes_exploracion())
	_preparar_captura()

## Modo captura, para revisar el aspecto sin tener que mirar la ventana:
##   godot --path . res://escenas/mundo.tscn -- --captura=ruta.png --hora=13
## Espera unos fotogramas (hay que dejar que se dibujen las partículas y la
## interfaz), guarda un PNG y cierra.
func _preparar_captura() -> void:
	var ruta := ""
	var espera := 0.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--captura="):
			ruta = arg.substr(10)
		elif arg.begins_with("--hora="):
			Reloj.hora = float(arg.substr(7))
		elif arg.begins_with("--zoom="):
			_camara.zoom = Vector2(float(arg.substr(7)), float(arg.substr(7)))
		elif arg.begins_with("--espera="):
			espera = float(arg.substr(9))
		elif arg == "--entrar":
			if not puertas.is_empty():
				Interiores.entrar(puertas[0], jugador)
		elif arg == "--modopixel":
			_camara.modo_pixel = true
		elif arg.begins_with("--nivelzoom="):
			_camara.modo_pixel = true
			_camara.zoom_a_nivel(int(arg.substr(12)))
		elif arg.begins_with("--mirar="):
			# --mirar=x,y : centra la cámara en una casilla concreta
			var pa := arg.substr(8).split(",")
			if pa.size() == 2:
				_camara.seguir(null)
				_camara.position = Iso.centro(int(pa[0]), int(pa[1]))
		elif arg == "--guardarahora":
			Guardado.guardar(RANURA_RAPIDA)
		elif arg == "--abrircofre":
			if Interiores.dentro() and not Interiores.activo.cofres.is_empty():
				Interiores.activo.cofres[0].interactuar(jugador)
		elif arg == "--sinhumo":
			for v: EdificioVisual in visuales.values():
				v.apagar_humo()
	if ruta == "":
		return
	if espera > 0.0:
		# Deja rodar el mundo: así el humo cuaja y la gente se ha movido.
		var hora_pedida := Reloj.hora
		await get_tree().create_timer(espera).timeout
		Reloj.hora = hora_pedida
	Reloj.pausado = true
	await get_tree().process_frame
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("[captura] guardada en %s" % ruta)
	get_tree().quit()

# ---------------------------------------------------------------------------
# MUNDO
# ---------------------------------------------------------------------------

func _construir_mundo() -> void:
	constructor = ConstructorTileset.new()
	var conjunto := constructor.construir(SEMILLA)
	isla = GeneradorIsla.new(ANCHO, ALTO, SEMILLA)

	_terreno = TileMapLayer.new()
	_terreno.name = "Terreno"
	_terreno.tile_set = conjunto
	_terreno.z_index = -20
	add_child(_terreno)

	_suelo_pueblo = TileMapLayer.new()
	_suelo_pueblo.name = "SueloPueblo"
	_suelo_pueblo.tile_set = conjunto
	_suelo_pueblo.z_index = -19
	add_child(_suelo_pueblo)

	# Los objetos se ordenan solos por profundidad: lo que está más abajo en
	# pantalla se dibuja encima. Es lo que hace que un pirata pase por delante
	# de una casa y por detrás de la siguiente.
	_objetos = Node2D.new()
	_objetos.name = "Objetos"
	_objetos.y_sort_enabled = true
	add_child(_objetos)

	transitable = TransitableIsla.new(isla)
	zona_exterior = ZonaExteriorScript.new()
	zona_exterior.montar("isla_principal", transitable, _objetos)
	add_child(zona_exterior)

	_pintar_terreno()
	_colocar_edificios()
	_pintar_plaza()
	_plantar_bosque()
	_crear_jugador()
	_crear_puertas()
	_crear_fuentes_recurso()
	_crear_parcela_cultivo()
	_crear_animales()
	Interiores.usar_exterior(self, self)

	_tinte = CanvasModulate.new()
	add_child(_tinte)

	_camara = CamaraIsla.new()
	add_child(_camara)
	_camara.make_current()
	_camara.limitar_a_casillas(transitable.limites())
	_camara.seguir(jugador)

## El jugador aparece donde lo dejó la partida guardada; si no hay partida, en
## la explanada, en la primera casilla libre junto al centro del pueblo.
func _crear_jugador() -> void:
	jugador = Jugador.new()
	jugador.name = "Jugador"
	jugador.transitable = transitable
	_objetos.add_child(jugador)
	_situar_jugador()
	# Al cargar una partida, Ubicacion ya trae la casilla buena: hay que
	# recolocarlo, porque el mundo se montó antes de leer el archivo.
	Guardado.partida_cargada.connect(func(_r): _al_cargar_partida())

## Restaura la situación completa: si la partida se hizo dentro de una casa,
## vuelve a entrar en ella y deja al jugador donde estaba; si no, lo coloca en
## el exterior.
func _al_cargar_partida() -> void:
	if Interiores.dentro():
		Interiores.salir(jugador)

	if Ubicacion.en_exterior():
		_situar_jugador()
		return

	var p := _puerta_por_edificio(Ubicacion.edificio_instancia)
	if p == null:
		# No se encontró la puerta: mejor salir a la calle que dejarlo colgado.
		push_warning("Partida guardada en '%s' pero no hay puerta para '%s'"
			% [Ubicacion.zona, Ubicacion.edificio_instancia])
		Ubicacion.volver_al_exterior(Ubicacion.retorno)
		_situar_jugador()
		return
	Interiores.entrar(p, jugador, Ubicacion.pos)

func _puerta_por_edificio(instancia: String) -> Puerta:
	for p in puertas:
		if p.edificio_instancia == instancia:
			return p
	return null

## Una puerta delante de cada edificio que tenga interior definido.
## La casilla es la que queda justo bajo el vértice inferior de la huella: en
## isométrico, "delante" es hacia abajo en la pantalla.
func _crear_puertas() -> void:
	# Mantener un orden estable. La Capitanía fue la primera puerta del
	# vertical slice y algunas integraciones existentes la usan como referencia.
	# Las nuevas puertas se añaden después sin cambiar esa compatibilidad.
	var orden: Array = casillas_edificio.keys()
	orden.sort_custom(func(a, b):
		if a == b:
			return false
		if str(a) == "capitania":
			return true
		if str(b) == "capitania":
			return false
		return str(a) < str(b)
	)
	for id_edificio: String in orden:
		var datos: EdificioData = BaseDeDatos.edificio(id_edificio)
		if datos == null or datos.interior == "":
			continue
		var v: EdificioVisual = visuales[id_edificio]
		var delante := Vector2i(v.casilla.x + v.lado, v.casilla.y + v.lado)
		delante = transitable.casilla_libre_cerca(delante, 4)

		var p := Puerta.new()
		p.name = "Puerta_" + id_edificio
		p.sentido = Puerta.Sentido.ENTRAR
		p.edificio_definicion = id_edificio
		p.edificio_instancia = v.identidad.instancia
		p.identidad = Entidades.identificar("objeto", "puerta",
			"puerta:%s" % v.identidad.instancia)
		Entidades.vincular(p.identidad, p)
		p.interior_id = datos.interior
		p.casilla_exterior = delante
		p.casilla_propia = delante
		p.position = Iso.centro_v(delante)
		p.z_index = -1                          ## el felpudo va bajo los pies
		_objetos.add_child(p)
		# Si el edificio está migrado al kit, su puerta también.
		var clave_kit := _clave_kit(id_edificio)
		if clave_kit != "":
			p.usar_asset(clave_kit + ".puerta")
		p.atravesada.connect(_al_cruzar_puerta)
		puertas.append(p)

## Primer recurso físico del mundo. La posición se obtiene de los datos del
## terreno, no de una coordenada frágil: playa pisable, junto a agua y libre
## de edificios. La clave natural mantiene su instance_id entre partidas.
func _crear_fuentes_recurso() -> void:
	_crear_fuentes_recurso_ampliadas()
	return
	# Compatibilidad con el primer prototipo; la versión ampliada de arriba
	# conserva la misma identidad natural del naufragio.
	var casilla := _buscar_costa_libre()
	if casilla.x < 0:
		push_warning("No se encontró una casilla costera para restos de naufragio")
		return
	var fuente = FuenteRecursoScript.new()
	fuente.name = "Fuente_RestosNaufragio"
	_objetos.add_child(fuente)
	var clave := Entidades.clave_en("restos_naufragio", casilla)
	if fuente.montar("restos_naufragio", clave, casilla):
		fuentes_recurso.append(fuente)
	else:
		fuente.queue_free()

func _crear_fuentes_recurso_ampliadas() -> void:
	var ubicadas: Array[Vector2i] = []
	var definiciones: Array = BaseDeDatos.fuentes.values()
	definiciones.sort_custom(func(a, b): return int(a.orden_mundo) < int(b.orden_mundo))
	for def: FuenteRecursoData in definiciones:
		if not def.generar_en_mundo:
			continue
		var casilla := Vector2i(-1, -1)
		if def.zona == "costa":
			casilla = _buscar_costa_libre()
		else:
			# El mapa actual aún no tiene biomas de bosque/montaña separados.
			# El criterio queda en datos para cambiarlo cuando se amplíe el mapa.
			casilla = _buscar_tierra_libre(def.espesura_min, def.espesura_max, ubicadas)
		if casilla.x < 0:
			push_warning("Diagnóstico: no hay casilla candidata para %s" % def.id)
			continue
		_montar_fuente_recurso(def.id, casilla)
		ubicadas.append(casilla)

func _montar_fuente_recurso(definicion_id: String, casilla: Vector2i) -> void:
	var fuente = FuenteRecursoScript.new()
	fuente.name = "Fuente_%s" % definicion_id
	_objetos.add_child(fuente)
	var clave := Entidades.clave_en(definicion_id, casilla)
	if fuente.montar(definicion_id, clave, casilla):
		fuentes_recurso.append(fuente)
	else:
		push_warning("No se pudo montar la fuente '%s' en %s" % [definicion_id, casilla])
		fuente.queue_free()

func _buscar_tierra_libre(espesura_min: float, espesura_max: float,
		excluir: Array[Vector2i]) -> Vector2i:
	for y in range(2, ALTO - 2):
		for x in range(2, ANCHO - 2):
			var t := Vector2i(x, y)
			if t in excluir or transitable.ocupadas.has(t):
				continue
			if not isla.es_transitable(x, y) or isla.es_explanada(x, y):
				continue
			var espesura := isla.espesura(x, y)
			if espesura < espesura_min or espesura > espesura_max:
				continue
			if Vector2(t - isla.centro_plaza).length() < 10.0:
				continue
			return t
	# Fallback deliberado: un mapa pequeño o muy edificado puede no cumplir el
	# criterio de bioma, pero la fuente sigue necesitando una instancia visible.
	for y in range(2, ALTO - 2):
		for x in range(2, ANCHO - 2):
			var t := Vector2i(x, y)
			if t in excluir or transitable.ocupadas.has(t):
				continue
			if not isla.es_transitable(x, y):
				continue
			return t
	return Vector2i(-1, -1)

func _buscar_costa_libre() -> Vector2i:
	for y in range(1, ALTO - 1):
		for x in range(1, ANCHO - 1):
			var t := Vector2i(x, y)
			if transitable.ocupadas.has(t) or not transitable.puede_pisar(t):
				continue
			var tiene_arena := false
			for nivel in isla.niveles_de(x, y):
				if int(nivel) == GeneradorIsla.ARENA:
					tiene_arena = true
					break
			if not tiene_arena:
				continue
			var junto_agua := false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if isla.nivel(x + d.x, y + d.y) == GeneradorIsla.AGUA:
					junto_agua = true
					break
			if junto_agua:
				return t
	return Vector2i(-1, -1)

func _crear_parcela_cultivo() -> void:
	var excluir: Array[Vector2i] = []
	for fuente in fuentes_recurso:
		excluir.append(fuente.casilla())
	for definicion_id in ["citricos", "cana_azucar", "tabaco"]:
		var casilla := _buscar_tierra_libre(0.0, 1.0, excluir)
		if casilla.x < 0:
			push_warning("No se encontró una casilla para la parcela '%s'" % definicion_id)
			continue
		var parcela = ParcelaCultivoScript.new()
		parcela.name = "Parcela_Cultivo_%s" % definicion_id
		_objetos.add_child(parcela)
		var clave := Entidades.clave_en(definicion_id, casilla)
		if parcela.montar(definicion_id, clave, casilla):
			parcelas_cultivo.append(parcela)
			excluir.append(casilla)
		else:
			parcela.queue_free()

func _crear_animales() -> void:
	var ubicadas: Array[Vector2i] = []
	var definiciones: Array = BaseDeDatos.animales.values()
	definiciones.sort_custom(func(a, b): return int(a.orden_mundo) < int(b.orden_mundo))
	var semilla := SEMILLA + 900
	for def: AnimalData in definiciones:
		if not def.generar_en_mundo:
			continue
		var casilla := Vector2i(-1, -1)
		match def.habitat:
			"costa":
				casilla = _buscar_costa_libre()
			"puerto":
				casilla = transitable.casilla_libre_cerca(_puerta_de("muelle_grua"), 6)
			_:
				casilla = _buscar_tierra_libre(0.25, 1.0, ubicadas)
		if casilla.x < 0 or casilla in ubicadas:
			push_warning("Diagnóstico: no hay casilla para el animal '%s'" % def.id)
			continue
		var animal = AnimalScript.new()
		animal.name = "Animal_%s" % def.id
		_objetos.add_child(animal)
		var clave := Entidades.clave_en("animal_" + def.id, casilla)
		if animal.montar(def.id, clave, casilla, transitable, semilla):
			animales.append(animal)
			ubicadas.append(casilla)
		else:
			animal.queue_free()
		semilla += 17

## Clave base del kit para un edificio, o "" si sigue con el arte antiguo.
## Comprueba que la pieza exista de verdad: un dato que apunte a un asset
## inexistente no debe dejar el mundo sin edificio.
func _clave_kit(id_edificio: String) -> String:
	var datos: EdificioData = BaseDeDatos.edificio(id_edificio)
	if datos == null or datos.asset_exterior == "":
		return ""
	if not Assets.existe(datos.asset_exterior + ".cuerpo"):
		push_warning("'%s' pide el asset '%s' y no está en el manifiesto"
			% [id_edificio, datos.asset_exterior])
		return ""
	return datos.asset_exterior

func _al_cruzar_puerta(p: Puerta) -> void:
	if p.sentido == Puerta.Sentido.ENTRAR:
		Interiores.entrar(p, jugador)

# ---------------------------------------------------------------------------
# LO QUE NECESITA EL GESTOR DE INTERIORES
# ---------------------------------------------------------------------------

func camara() -> CamaraIsla:
	return _camara

func limites_exterior() -> Rect2i:
	return zona_exterior.limites() if zona_exterior != null else transitable.limites()

## Apaga o enciende la isla entera. Cuando el mundo crezca y haya que liberar
## memoria de verdad, este es el único sitio que cambia.
func mostrar_exterior(visible_ahora: bool) -> void:
	_terreno.visible = visible_ahora
	_suelo_pueblo.visible = visible_ahora
	_objetos.visible = visible_ahora
	_objetos.process_mode = Node.PROCESS_MODE_INHERIT if visible_ahora \
		else Node.PROCESS_MODE_DISABLED

## Devuelve al jugador al exterior en la casilla indicada.
func recibir_jugador(quien: Jugador, en: Vector2) -> void:
	if zona_exterior != null:
		zona_exterior.recibir(quien, en)
		return
	if quien.get_parent() != _objetos:
		quien.reparent(_objetos, false)
		quien.transitable = transitable
	if transitable.cabe_en(en, quien.huella):
		quien.colocar(en)
	else:
		quien.colocar_seguro(en)

func _situar_jugador() -> void:
	if not (Ubicacion.hay_dato and Ubicacion.en_exterior()):
		jugador.colocar_seguro(Vector2(isla.centro_plaza) + Vector2(0.5, 0.5))
		return
	jugador.direccion = Ubicacion.direccion
	# Exacto si la casilla sigue siendo pisable; si algo la bloqueó desde que
	# se guardó, al hueco más cercano en vez de dejarlo atrapado.
	if transitable.cabe_en(Ubicacion.pos, jugador.huella):
		jugador.colocar(Ubicacion.pos)
	else:
		jugador.colocar_seguro(Ubicacion.pos)

func _pintar_terreno() -> void:
	for y in ALTO:
		for x in ANCHO:
			var niveles := isla.niveles_de(x, y)
			var r: Array
			if niveles.min() == niveles.max() and int(niveles[0]) == GeneradorIsla.HIERBA:
				# Hierba pura: la variante la elige el ruido, en manchas.
				r = constructor.puro_de(isla.variante_hierba(x, y))
			else:
				r = constructor.resolver(niveles)
			if r[0] >= 0:
				_terreno.set_cell(Vector2i(x, y), r[0], r[1])

## Explanada de tierra pisoteada bajo el pueblo, con el borde difuminado en la
## hierba mediante las mismas transiciones por esquinas que la playa.
## Sólo donde no hay edificio: no tiene sentido pintar bajo una casa.
func _pintar_plaza() -> void:
	var ocupadas: Dictionary = transitable.ocupadas
	for y in ALTO:
		for x in ANCHO:
			var t := Vector2i(x, y)
			if ocupadas.has(t) or not isla.es_tierra(x, y):
				continue
			var niveles := isla.niveles_plaza(x, y)
			if niveles.max() != GeneradorIsla.TIERRA:
				continue                        # ni una esquina pisada: sigue siendo prado
			var r := constructor.resolver(niveles)
			if r[0] >= 0:
				_suelo_pueblo.set_cell(t, r[0], r[1])

func _plantar_bosque() -> void:
	if constructor.fuente_bosque < 0:
		return
	for y in ALTO:
		for x in ANCHO:
			if not isla.es_tierra(x, y):
				continue
			if isla.espesura(x, y) < 0.28:
				continue
			if _suelo_pueblo.get_cell_source_id(Vector2i(x, y)) != -1:
				continue                        # no plantar sobre la explanada
			_suelo_pueblo.set_cell(Vector2i(x, y), constructor.fuente_bosque,
				constructor.celda_al_azar(constructor.celdas_bosque))

func _colocar_edificios() -> void:
	# La ocupación va directa al mapa de transitabilidad, para que sobreviva a
	# esta función en vez de perderse como antes.
	var ocupadas: Dictionary = transitable.ocupadas
	# Se colocan de mayor a menor: si no, los grandes no encuentran hueco.
	var orden := REPARTO.keys()
	orden.sort_custom(func(a, b):
		var la := int(EdificioVisual.MODELOS[REPARTO[a]["modelo"]]["lado"])
		var lb := int(EdificioVisual.MODELOS[REPARTO[b]["modelo"]]["lado"])
		# Desempatar por id NO es cosmético: la ordenación de Godot no es
		# estable, así que dos edificios del mismo tamaño podían intercambiarse
		# entre ejecuciones. Y como el sorteo de solares consume el generador
		# en ese orden, cambiaban los solares, y con ellos las claves naturales
		# y los id de instancia. Sin esto, una partida guardada podía no
		# reconocer sus propios edificios al reabrir el juego.
		if la != lb:
			return la > lb
		return str(a) < str(b))

	for id: String in orden:
		var cfg: Dictionary = REPARTO[id]
		# ¿Este edificio ya tiene arte en el manifiesto? Lo dice el DATO, no un
		# `if` con su nombre. Mientras `asset_exterior` esté vacío usa el arte
		# viejo; en cuanto se rellena, pasa al kit. Reversible borrando la línea.
		var clave_kit := _clave_kit(id)
		var lado := int(EdificioVisual.MODELOS[cfg["modelo"]]["lado"])
		if clave_kit != "":
			lado = Assets.huella(clave_kit + ".cuerpo").x

		var casilla := isla.hueco_libre(lado, ocupadas)
		if casilla.x < 0:
			push_warning("Sin sitio para %s" % id)
			continue
		isla.marcar_ocupado(casilla, lado, ocupadas, id)
		casillas_edificio[id] = casilla

		var v := EdificioVisual.new()
		v.name = id
		_objetos.add_child(v)
		if clave_kit != "":
			v.montar_kit(id, clave_kit, casilla)
		else:
			v.montar(id, cfg["modelo"], casilla, int(cfg["angulo"]))
		# Identidad de instancia por clave natural: el mismo edificio en la
		# misma casilla recibe siempre el mismo id, aunque se regenere el mundo
		# o se cargue la partida. Dos tabernas en sitios distintos, dos ids.
		v.identidad = Entidades.identificar("edificio", id, Entidades.clave_en(id, casilla))
		Entidades.vincular(v.identidad, v)
		visuales[id] = v

# ---------------------------------------------------------------------------
# LOGÍSTICA (lo mismo que en el panel de mando, ahora sobre el mapa)
# ---------------------------------------------------------------------------

func _montar_logistica() -> void:
	for par in [["ron", 30], ["raciones", 40], ["doblon", 900], ["madera_naufragio", 60],
			["polvora_humeda", 25], ["carbon", 30], ["acero_imperial", 12],
			["aceite_imperial", 4], ["grasa_ballena", 30], ["azufre_volcanico", 18],
			["seda_robada", 6], ["cuero", 10]]:
		Almacen.anadir(par[0], par[1], "inicio")

	for id in PUESTOS:
		Plantel.reclutar(id)
		Plantel.asignar(id, PUESTOS[id])

	_abrir("taberna", "servicio_taberna", 3, "tabernero", ["trabajar", "taberna"])
	_abrir("herreria", "forjar_canon", 4, "herrero")
	_abrir("herreria", "secar_polvora", 2, "herrero")
	_abrir("muelle_grua", "rastrillar_marea", 3, "muelle")
	_abrir("muelle_grua", "curar_madera", 2, "muelle")
	_abrir("corrales", "salar_carne", 1)
	_abrir("capilla", "curar_heridos", 1)
	MuelleManager.montar(fuentes_recurso)
	_montar_puesto_muelle()

	var taberna := _puerta_de("taberna")
	var semilla := SEMILLA
	for id: String in PUESTOS:
		var p := Pirata.new()
		_objetos.add_child(p)
		p.transitable = transitable
		var datos: PersonajeData = BaseDeDatos.personaje(id)
		p.montar(id, datos.nombre if datos != null else id, _puerta_de(PUESTOS[id]), taberna,
			semilla, datos.horario_id if datos != null else "tripulacion")
		piratas.append(p)
		semilla += 31

	# Tripulacion anonima, para que el pueblo no parezca desierto.
	var destinos := casillas_edificio.keys()
	for i in 10:
		var p := Pirata.new()
		_objetos.add_child(p)
		p.transitable = transitable
		p.montar("", "Marinero", _puerta_de(destinos[i % destinos.size()]), taberna, semilla)
		piratas.append(p)
		semilla += 31

func _montar_puesto_muelle() -> void:
	if not casillas_edificio.has("muelle_grua"):
		return
	var puesto := PuestoMuelleScript.new()
	puesto.name = "PuestoGestionMuelle"
	puesto.position = Iso.centro_v(_puerta_de("muelle_grua"))
	_objetos.add_child(puesto)
	puesto.gestionar.connect(func(estado: String): panel_muelle.abrir(estado))

	# Tripulación anónima, para que el pueblo no parezca desierto.

## La casilla de un edificio es su esquina de atrás; si un pirata se planta
## ahí, el sprite del edificio se lo come. Esto devuelve el suelo de DELANTE,
## que en isométrico es hacia abajo en pantalla.
func _puerta_de(edificio: String) -> Vector2i:
	if not casillas_edificio.has(edificio):
		return isla.centro_plaza
	var c: Vector2i = casillas_edificio[edificio]
	var lado := 4
	if visuales.has(edificio):
		lado = (visuales[edificio] as EdificioVisual).lado
	return Vector2i(c.x + lado, c.y + lado)

func _abrir(edificio: String, receta: String, gente: int, horario_id: String = "",
		actividades_productivas: Array = ["trabajar"]) -> void:
	var e := EstacionTrabajo.new()
	e.edificio_id = edificio
	e.receta_id = receta
	e.trabajadores = gente
	e.horario_id = horario_id
	e.actividades_productivas = actividades_productivas
	e.name = "%s_%s" % [edificio, receta]
	add_child(e)
	estaciones.append(e)
	if visuales.has(edificio):
		var v: EdificioVisual = visuales[edificio]
		v.estaciones.append(e)

# ---------------------------------------------------------------------------
# CICLO DÍA / NOCHE
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	_tinte.color = _luz(Reloj.hora)
	_actualizar_hud()
	_raton_sobre_edificio()
	_actualizar_oclusiones()

func _actualizar_oclusiones() -> void:
	if jugador == null or Interiores.dentro():
		return
	for v: EdificioVisual in visuales.values():
		v.actualizar_occlusion(jugador.global_position)

## Amanecer cálido, mediodía neutro, atardecer anaranjado, noche azul.
func _luz(hora: float) -> Color:
	var claves := [
		[0.0,  Color(0.30, 0.36, 0.58)],
		[5.5,  Color(0.42, 0.42, 0.60)],
		[7.0,  Color(0.92, 0.78, 0.66)],
		[10.0, Color(1.00, 0.99, 0.96)],
		[16.0, Color(1.00, 0.97, 0.90)],
		[19.0, Color(0.98, 0.74, 0.52)],
		[21.0, Color(0.44, 0.42, 0.62)],
		[24.0, Color(0.30, 0.36, 0.58)],
	]
	for i in range(claves.size() - 1):
		var a: Array = claves[i]
		var b: Array = claves[i + 1]
		if hora >= float(a[0]) and hora <= float(b[0]):
			var t := inverse_lerp(float(a[0]), float(b[0]), hora)
			return (a[1] as Color).lerp(b[1] as Color, t)
	return Color.WHITE

# ---------------------------------------------------------------------------
# RATÓN
# ---------------------------------------------------------------------------

func _raton_sobre_edificio() -> void:
	# Dentro de una casa el exterior está oculto: señalar sus edificios con el
	# ratón no tiene sentido y confunde.
	if Interiores.dentro():
		if _bajo_raton != null:
			_bajo_raton.resaltar(false)
			_bajo_raton = null
		return
	var p := get_global_mouse_position()
	var encontrado: EdificioVisual = null
	# De abajo hacia arriba: gana el que está más cerca del espectador.
	var lista := visuales.values()
	lista.sort_custom(func(a, b): return a.position.y > b.position.y)
	for v: EdificioVisual in lista:
		if v.contiene(p):
			encontrado = v
			break
	if encontrado == _bajo_raton:
		return
	if _bajo_raton != null:
		_bajo_raton.resaltar(false)
	_bajo_raton = encontrado
	if _bajo_raton != null:
		_bajo_raton.resaltar(true)

# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------

var _lbl_reloj: Label
var _lbl_motin: Label
var _barra_motin: ProgressBar
var _lbl_recursos: RichTextLabel
var _lbl_ficha: RichTextLabel
var _lbl_bitacora: RichTextLabel
var _lbl_accion: Label
var panel_cofre: PanelCofre
var panel_crafteo
var panel_mochila
var panel_mercado
var panel_taberna
var panel_muelle
var _lbl_partida: Label
var _fundido_aviso: Tween
var _bitacora: Array[String] = []

func _montar_hud() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_hud)

	# --- barra superior ---
	var arriba := _caja(Vector2(12, 10), Vector2(430, 74))
	_hud.add_child(arriba)
	var v := _dentro(arriba)
	_lbl_reloj = Label.new()
	_lbl_reloj.add_theme_font_size_override("font_size", 20)
	_lbl_reloj.add_theme_color_override("font_color", Color("e8c76a"))
	v.add_child(_lbl_reloj)
	_lbl_motin = Label.new()
	_lbl_motin.add_theme_color_override("font_color", Color("d9dde6"))
	v.add_child(_lbl_motin)
	_barra_motin = ProgressBar.new()
	_barra_motin.max_value = 100.0
	_barra_motin.show_percentage = false
	_barra_motin.custom_minimum_size.y = 12
	v.add_child(_barra_motin)

	# --- recursos, derecha ---
	var der := _caja(Vector2(-306, 10), Vector2(294, 330))
	der.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	der.position = Vector2(-306, 10)
	_hud.add_child(der)
	var v2 := _dentro(der)
	v2.add_child(_titulo("COFRES · PUERTO · MAR"))
	_lbl_recursos = _texto()
	v2.add_child(_lbl_recursos)

	# --- ficha del edificio bajo el ratón ---
	var ficha := _caja(Vector2(12, 96), Vector2(430, 150))
	_hud.add_child(ficha)
	var v3 := _dentro(ficha)
	v3.add_child(_titulo("EDIFICIO"))
	_lbl_ficha = _texto()
	v3.add_child(_lbl_ficha)

	# --- bitácora abajo ---
	var abajo := _caja(Vector2(12, -186), Vector2(560, 174))
	abajo.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, true)
	abajo.position = Vector2(12, -186)
	_hud.add_child(abajo)
	var v4 := _dentro(abajo)
	v4.add_child(_titulo("BITÁCORA"))
	_lbl_bitacora = _texto()
	_lbl_bitacora.scroll_following = true
	v4.add_child(_lbl_bitacora)

	# --- botones ---
	var botones := HBoxContainer.new()
	botones.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, true)
	botones.position = Vector2(-660, -46)
	botones.custom_minimum_size = Vector2(648, 32)
	botones.add_theme_constant_override("separation", 6)
	_hud.add_child(botones)
	_boton(botones, "Cortar el acero", func():
		Almacen.mermar("aceite_imperial", Almacen.cantidad("aceite_imperial"), "bloqueo naval"))
	_boton(botones, "Vaciar el ron", func():
		Almacen.mermar("ron", Almacen.cantidad("ron"), "sabotaje"))
	_boton(botones, "Reponer", _reponer)
	_boton(botones, "×6", func(): Reloj.velocidad = 6.0 if Reloj.velocidad == 1.0 else 1.0)
	_boton(botones, "Pausa", func(): Reloj.pausado = not Reloj.pausado)

	# Aviso de interacción, centrado sobre la barra de botones.
	_lbl_accion = Label.new()
	_lbl_accion.set_anchors_preset(Control.PRESET_CENTER_BOTTOM, true)
	_lbl_accion.position = Vector2(-220, -120)
	_lbl_accion.custom_minimum_size = Vector2(440, 0)
	_lbl_accion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_accion.add_theme_font_size_override("font_size", 20)
	_lbl_accion.add_theme_color_override("font_color", GlobalColors.get_color_interaccion())
	_lbl_accion.add_theme_color_override("font_outline_color",
		GlobalColors.con_alpha("vacio_abismal", 0.95))
	_lbl_accion.add_theme_constant_override("outline_size", 8)
	_lbl_accion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_accion.visible = false
	_hud.add_child(_lbl_accion)
	jugador.objetivo_cambiado.connect(_al_cambiar_objetivo)

	# Panel del cofre. Lo avisa el interior a través del gestor, así que el
	# cofre no necesita saber que existe una interfaz.
	panel_cofre = PanelCofre.new()
	panel_cofre.set_anchors_preset(Control.PRESET_CENTER, true)
	panel_cofre.position = Vector2(-160, -110)
	_hud.add_child(panel_cofre)
	Interiores.cofre_abierto.connect(func(c: Cofre): panel_cofre.abrir(c))
	Interiores.salio.connect(func(_i): panel_cofre.cerrar_panel())

	# Panel de fabricación manual. La estación sólo emite su identificador;
	# ninguna receta ni inventario queda acoplada a la interfaz.
	panel_crafteo = PanelCrafteoScript.new()
	panel_crafteo.set_anchors_preset(Control.PRESET_CENTER, true)
	panel_crafteo.position = Vector2(-195, -180)
	_hud.add_child(panel_crafteo)
	CraftingManager.estacion_abierta.connect(func(id: String): panel_crafteo.abrir(id))
	Interiores.salio.connect(func(_i): panel_crafteo.cerrar_panel())

	# La mochila es sólo una vista del estado de Bolsa; no duplica Inventario.
	panel_mochila = PanelMochilaScript.new()
	panel_mochila.set_anchors_preset(Control.PRESET_CENTER, true)
	panel_mochila.position = Vector2(-180, -185)
	_hud.add_child(panel_mochila)
	Interiores.salio.connect(func(_i): panel_mochila.cerrar_panel())

	panel_mercado = PanelMercadoScript.new()
	panel_mercado.set_anchors_preset(Control.PRESET_CENTER, true)
	panel_mercado.position = Vector2(-220, -190)
	_hud.add_child(panel_mercado)
	MercadoManager.mercado_abierto.connect(func(): panel_mercado.abrir())
	Interiores.salio.connect(func(_i): panel_mercado.cerrar_panel())

	panel_taberna = PanelTabernaScript.new()
	panel_taberna.set_anchors_preset(Control.PRESET_CENTER, true)
	panel_taberna.position = Vector2(-175, -150)
	_hud.add_child(panel_taberna)
	TabernaManager.taberna_abierta.connect(func(): panel_taberna.abrir())
	Interiores.salio.connect(func(_i): panel_taberna.cerrar_panel())

	panel_muelle = PanelMuelleScript.new()
	panel_muelle.set_anchors_preset(Control.PRESET_CENTER, true)
	panel_muelle.position = Vector2(-215, -150)
	_hud.add_child(panel_muelle)
	Interiores.salio.connect(func(_i): panel_muelle.cerrar_panel())

	# Aviso de guardado. Sin esto, pulsar F5 no da ninguna señal de vida y no
	# sabes si guardó, si falló o si la tecla no hace nada.
	_lbl_partida = Label.new()
	_lbl_partida.set_anchors_preset(Control.PRESET_CENTER_TOP, true)
	_lbl_partida.position = Vector2(-220, 22)
	_lbl_partida.custom_minimum_size = Vector2(440, 0)
	_lbl_partida.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_partida.add_theme_font_size_override("font_size", 19)
	_lbl_partida.add_theme_color_override("font_outline_color",
		GlobalColors.con_alpha("vacio_abismal", 0.95))
	_lbl_partida.add_theme_constant_override("outline_size", 8)
	_lbl_partida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_partida.modulate.a = 0.0
	_hud.add_child(_lbl_partida)

	Guardado.guardado_hecho.connect(func(r): _avisar_partida(
		"Partida guardada (ranura %d)" % r, GlobalColors.color("verde_brillo")))
	Guardado.partida_cargada.connect(func(r): _avisar_partida(
		"Partida cargada (ranura %d)" % r, GlobalColors.get_color_interaccion()))
	Guardado.fallo.connect(func(m): _avisar_partida(m, GlobalColors.get_color_peligro()))

func _avisar_partida(texto: String, color: Color) -> void:
	_lbl_partida.text = texto
	_lbl_partida.add_theme_color_override("font_color", color)
	_lbl_partida.modulate.a = 1.0
	if _fundido_aviso != null and _fundido_aviso.is_valid():
		_fundido_aviso.kill()
	_fundido_aviso = create_tween()
	_fundido_aviso.tween_interval(1.6)
	_fundido_aviso.tween_property(_lbl_partida, "modulate:a", 0.0, 0.8)
	_apuntar(texto)

func _al_cambiar_objetivo(obj: Interactuable) -> void:
	if obj == null:
		_lbl_accion.visible = false
		return
	_lbl_accion.text = "[E]  %s" % obj.texto_accion()
	_lbl_accion.visible = true

func _caja(pos: Vector2, tam: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0.07, 0.08, 0.11, 0.82)
	e.set_corner_radius_all(6)
	e.border_color = Color(0.30, 0.27, 0.20, 0.7)
	e.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", e)
	p.position = pos
	p.custom_minimum_size = tam
	p.size = tam
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _dentro(caja: PanelContainer) -> VBoxContainer:
	var m := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 9)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	return v

func _titulo(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color("8b94a6"))
	return l

func _texto() -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_color_override("default_color", Color("d9dde6"))
	r.add_theme_font_size_override("normal_font_size", 13)
	return r

func _boton(padre: HBoxContainer, texto: String, accion: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(accion)
	padre.add_child(b)

func _reponer() -> void:
	for par in [["ron", 20], ["raciones", 25], ["doblon", 400], ["acero_imperial", 8],
			["carbon", 20], ["aceite_imperial", 4]]:
		Almacen.anadir(par[0], par[1], "mercader")
	_apuntar("Un mercader corrupto descarga suministros en el muelle.")

func _actualizar_hud() -> void:
	_lbl_reloj.text = Reloj.texto()
	_barra_motin.value = Motin.nivel
	var e := StyleBoxFlat.new()
	e.bg_color = Motin.color_barra()
	e.set_corner_radius_all(3)
	_barra_motin.add_theme_stylebox_override("fill", e)
	_lbl_motin.text = "Motín %d/100 (%s) · %d piratas" % [
		int(Motin.nivel), Motin.estado_texto(), Motin.tripulacion]

	var global := RastreoCarga.inventario_global()
	var claves := global.keys()
	claves.sort_custom(func(a, b): return BaseDeDatos.nombre_item(a) < BaseDeDatos.nombre_item(b))
	var lineas := []
	for id in claves:
		var g: Dictionary = global[id]
		if int(g["total"]) <= 0:
			continue
		var flota := ""
		if int(g["puerto"]) + int(g["mar"]) > 0:
			flota = " [color=#5b9bd5]· %d · %d[/color]" % [g["puerto"], g["mar"]]
		lineas.append("%s  [b]%d[/b]%s" % [BaseDeDatos.nombre_item(id), g["cofres"], flota])
	lineas.append("")
	lineas.append("[color=#f5c051][b]RASTREO DE LA ISLA[/b][/color]")
	lineas.append(_resumen_fuentes_exploracion())
	lineas.append(_resumen_cultivos_exploracion())
	_lbl_recursos.text = "\n".join(lineas)

	_lbl_ficha.text = _ficha()

func _ficha() -> String:
	if Interiores.dentro():
		var def: InteriorDefinicion = BaseDeDatos.interior(Ubicacion.zona)
		var titulo := def.nombre if def != null else Ubicacion.zona
		return "[b]%s[/b]\n[color=#8b94a6]Estás dentro. Busca la puerta para salir.[/color]" % titulo
	if _bajo_raton == null:
		return "[color=#7d8798]Pasa el ratón por un edificio.[/color]"
	var v := _bajo_raton
	var lineas := ["[b]%s[/b]" % v.nombre()]
	var d: EdificioData = BaseDeDatos.edificio(v.edificio_id)
	if d != null:
		lineas.append("[color=#8b94a6]%s[/color]" % d.descripcion)
	for e in v.estaciones:
		var r: RecetaData = BaseDeDatos.receta(e.receta_id)
		var nombre_r := r.nombre if r != null else e.receta_id
		var color := "#c0392b" if e.parada else "#7fc47f"
		lineas.append("[color=%s]%s — %s (%d%%)[/color]"
			% [color, nombre_r, e.estado_texto(), int(e.porcentaje() * 100)])
		if e.parada:
			lineas.append("  [color=#c0392b]%s[/color]" % e.ultimo_motivo)
	var gente := []
	for id in PUESTOS:
		if PUESTOS[id] == v.edificio_id and id in Plantel.reclutados:
			var p: PersonajeData = BaseDeDatos.personaje(id)
			if p != null:
				gente.append(p.nombre)
	if not gente.is_empty():
		lineas.append("[color=#e8c76a]%s[/color]" % ", ".join(gente))
	return "\n".join(lineas)

# ---------------------------------------------------------------------------

func _conectar() -> void:
	MuelleManager.grua_activada.connect(_al_activar_grua)
	MuelleManager.lote_recolectado.connect(func(productos):
		var entregas: Array[String] = []
		for id in productos:
			entregas.append("%d× %s" % [int(productos[id]), BaseDeDatos.nombre_item(str(id))])
		_apuntar("[color=#5cb2b5]La red del muelle recolectó: %s[/color]" % ", ".join(entregas)))
	if MuelleManager.grua_activa:
		_desactivar_rastrillo_marea()
	for fuente in fuentes_recurso:
		fuente.recolectado.connect(_al_recolectar_recurso)
	for parcela in parcelas_cultivo:
		parcela.accion_realizada.connect(_al_accion_parcela)
	RecursosMundo.fuente_cambiada.connect(func(_instancia, _cantidad):
		_apuntar(_resumen_fuentes_exploracion()))
	Almacen.cuello_de_botella.connect(func(est, insumo, faltan):
		_apuntar("[color=#c0392b]%s necesita %d× %s[/color]"
			% [_nombre(est), faltan, BaseDeDatos.nombre_item(insumo)]))
	Almacen.sustitucion_aplicada.connect(func(est, orig, sust, n):
		_apuntar("[color=#5b9bd5]PLAN B en %s: %d× %s en vez de %s[/color]"
			% [_nombre(est), n, BaseDeDatos.nombre_item(sust), BaseDeDatos.nombre_item(orig)]))
	Almacen.cuello_resuelto.connect(func(est, insumo):
		_apuntar("[color=#4caf50]%s vuelve a tener %s[/color]"
			% [_nombre(est), BaseDeDatos.nombre_item(insumo)]))
	Motin.incidente.connect(func(tipo, detalle):
		_apuntar("[color=#c0392b][%s] %s[/color]" % [tipo, detalle]))
	Motin.carencia.connect(func(id, n):
		_apuntar("[color=#c0392b]Faltan %d× %s para la tripulación[/color]"
			% [n, BaseDeDatos.nombre_item(id)]))
	Reloj.nuevo_dia.connect(func(d): _apuntar("[b]— Día %d —[/b]" % d))
	_apuntar("La guarida despierta. Rueda del ratón para acercar, botón derecho para mover.")

func _resumen_fuentes_exploracion() -> String:
	var lineas: Array[String] = []
	for fuente in fuentes_recurso:
		if fuente.cantidad() <= 0:
			continue
		var def: Resource = fuente.definicion()
		var nombre: String = str(def.nombre if def != null else fuente.definicion_id)
		lineas.append("%s al %s" % [nombre, _direccion_fuente(fuente.casilla())])
	if lineas.is_empty():
		return "[color=#7d8798]No hay recursos silvestres disponibles.[/color]"
	return "[color=#5cb2b5]Rastreo de la isla: %s.[/color]" % ", ".join(lineas)

func _resumen_cultivos_exploracion() -> String:
	var lineas: Array[String] = []
	for parcela in parcelas_cultivo:
		if parcela == null or not is_instance_valid(parcela):
			continue
		var def: CultivoData = parcela.definicion()
		var nombre := str(def.nombre if def != null else parcela.definicion_id)
		var etapa := CultivosMundo.etapa(parcela.identidad.instancia)
		var estado := "sin sembrar"
		if etapa == 1 or etapa == 2:
			estado = "creciendo"
		elif etapa == 3:
			estado = "lista"
		lineas.append("%s (%s) al %s" % [nombre, estado, _direccion_fuente(parcela.casilla())])
	if lineas.is_empty():
		return "[color=#7d8798]No hay parcelas registradas.[/color]"
	return "[color=#82b06b]Cultivos: %s[/color]" % ", ".join(lineas)

func _direccion_fuente(casilla: Vector2i) -> String:
	var delta: Vector2 = Vector2(casilla) + Vector2(0.5, 0.5) - jugador.pos_tile
	if delta.length_squared() < 0.01:
		return "aquí"
	if abs(delta.x) >= abs(delta.y):
		return "el este" if delta.x > 0 else "el oeste"
	return "el sur" if delta.y > 0 else "el norte"

func _al_recolectar_recurso(fuente: FuenteRecurso, ciclos: int, productos: Dictionary) -> void:
	var entregas: Array[String] = []
	for id in productos:
		entregas.append("%d× %s" % [int(productos[id]), BaseDeDatos.nombre_item(str(id))])
	entregas.sort()
	_apuntar("[color=#f5c051]Recolectado en %s: %s[/color]"
		% [fuente.definicion().nombre, ", ".join(entregas)])

func _al_activar_grua() -> void:
	_desactivar_rastrillo_marea()
	_apuntar("[color=#f5c051]Red de arrastre instalada: la marea se recoge desde la costa.[/color]")

func _desactivar_rastrillo_marea() -> void:
	for estacion in estaciones:
		if estacion.edificio_id == "muelle_grua" and estacion.receta_id == "rastrillar_marea":
			estacion.activa = false

func _al_accion_parcela(parcela: ParcelaCultivo, accion: String, productos: Dictionary) -> void:
	var def: Resource = parcela.definicion()
	if accion == "sembrar":
		_apuntar("[color=#82b06b]Sembraste %s. Estará listo en %.0f horas.[/color]"
			% [def.nombre, def.horas_crecimiento])
		return
	var entregas: Array[String] = []
	for id in productos:
		entregas.append("%d× %s" % [int(productos[id]), BaseDeDatos.nombre_item(str(id))])
	entregas.sort()
	_apuntar("[color=#f5c051]Cosecha de %s: %s[/color]" % [def.nombre, ", ".join(entregas)])

func _apuntar(t: String) -> void:
	_bitacora.append("[color=#7d8798]%s[/color]  %s" % [Reloj.texto(), t])
	if _bitacora.size() > 60:
		_bitacora.pop_front()
	_lbl_bitacora.text = "\n".join(_bitacora)

func _nombre(id: String) -> String:
	var e: EdificioData = BaseDeDatos.edificio(id)
	return e.nombre if e != null else id

## Antirrebote de guardado rápido: machacar F9 mientras el mundo se reconstruye
## es la forma más fácil de dejarlo a medias.
const ESPERA_ENTRE_PARTIDAS := 0.6
const RANURA_RAPIDA := 1

var _ultima_partida_ms: int = -99999

func _puede_tocar_partida() -> bool:
	if Guardado.ocupado:
		return false
	return Time.get_ticks_msec() - _ultima_partida_ms > int(ESPERA_ENTRE_PARTIDAS * 1000.0)

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("inventario"):
		if panel_mochila.abierto():
			panel_mochila.cerrar_panel()
		else:
			panel_cofre.cerrar_panel()
			panel_crafteo.cerrar_panel()
			panel_mochila.abrir()
		get_viewport().set_input_as_handled()
		return
	if MercadoManager.abierto and evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		panel_mercado.cerrar_panel()
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("guardar_rapido"):
		if _puede_tocar_partida():
			_ultima_partida_ms = Time.get_ticks_msec()
			Guardado.guardar(RANURA_RAPIDA)
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("cargar_rapido"):
		if _puede_tocar_partida():
			_ultima_partida_ms = Time.get_ticks_msec()
			Guardado.cargar(RANURA_RAPIDA)
		get_viewport().set_input_as_handled()
		return

	if evento is InputEventKey and evento.pressed and not evento.echo:
		if evento.keycode == KEY_SPACE:
			Reloj.pausado = not Reloj.pausado
		elif evento.keycode == KEY_ESCAPE and not panel_cofre.abierto() and not panel_crafteo.abierto() and not panel_mochila.abierto() and not panel_mercado.abierto() and not panel_taberna.abierto() and not panel_muelle.abierto():
			get_tree().quit()
