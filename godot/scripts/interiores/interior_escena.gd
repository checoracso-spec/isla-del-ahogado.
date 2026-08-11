class_name InteriorEscena
extends Zona
## Un interior construido a partir de su definición.
##
## Todo el dibujo de aquí es PROVISIONAL y está hecho por código: rombos de
## suelo, muros extruidos y cajas para los muebles. Es a propósito — sirve para
## probar la mecánica de entrar y salir sin esperar al arte.
##
## Sólo se levantan las paredes del FONDO (norte y oeste). Las de delante se
## dejan abiertas, que es como se ven los interiores en las referencias, y de
## paso evita el problema de que una pared tape al jugador.

const COLOR_SUELO := {
	"madera": [Color("6b4a2c"), Color("5d4026")],
	"piedra": [Color("6f6f73"), Color("616166")],
	"tierra": [Color("6a563c"), Color("5c4a33")],
}
const COLOR_MURO := Color("4a3a2c")
const COLOR_MURO_CIMA := Color("6a5340")
const ALTURA_MURO := 46.0
const TransicionZonaScript := preload("res://scripts/interiores/transicion_zona.gd")
const EstacionCrafteoScript := preload("res://scripts/interiores/estacion_crafteo.gd")
const PuestoMercadoScript := preload("res://scripts/interiores/puesto_mercado.gd")
const PuestoTabernaScript := preload("res://scripts/interiores/puesto_taberna.gd")
const MuebleVisualScript := preload("res://scripts/interiores/mueble_visual.gd")

signal cofre_abierto(cofre: Cofre)
signal transicion_solicitada(transicion: Interactuable, quien: Node)

var definicion: InteriorDefinicion
var puerta_salida: Puerta
var identidad: Identidad                 ## el interior DE ESTE edificio
var cofres: Array[Cofre] = []
var transiciones: Array[Interactuable] = []
var casilla_exterior: Vector2i
var edificio_definicion: String = ""
var edificio_instancia: String = ""
var _arte_base: Node2D
var _decoracion_suelo: Node2D
var _decoracion_pared: Node2D
var _efectos: Node2D
var _arte_base_activo := false

func construir(def: InteriorDefinicion, casilla_exterior: Vector2i,
		edificio_definicion: String, edificio_instancia: String,
		p_identidad: Identidad = null) -> void:
	definicion = def
	identidad = p_identidad
	self.casilla_exterior = casilla_exterior
	self.edificio_definicion = edificio_definicion
	self.edificio_instancia = edificio_instancia
	id = def.id
	name = "Interior_" + def.id

	var rejilla := TransitableRejilla.new(def.ancho, def.alto)
	rejilla.amurallar()
	for m in def.muebles:
		var mueble: Dictionary = m
		if bool(mueble.get("solido", true)):
			var origen := _casilla_de(mueble)
			var h := _huella_de(mueble)
			for dy in h.y:
				for dx in h.x:
					rejilla.bloquear(origen + Vector2i(dx, dy), "mueble")
	transitable = rejilla

	# La entrada tiene que ser pisable aunque los datos digan otra cosa.
	rejilla.liberar(def.entrada_valida())

	if actores == null:
		actores = Node2D.new()
		actores.name = "Actores"
		actores.y_sort_enabled = true
		add_child(actores)

	_montar_arte_base(def)
	_montar_muebles_visual(def)
	_montar_transiciones(def)

	if def.salida_exterior:
		_montar_puerta_salida(def, casilla_exterior, edificio_definicion, edificio_instancia)
	_montar_cofres(def)
	queue_redraw()

## Monta suelo y paredes desde el manifiesto sin mezclar rutas con la lógica.
## Si falta una de las tres claves, se conserva entero el dibujo provisional.
func _montar_arte_base(def: InteriorDefinicion) -> void:
	_arte_base_activo = def.asset_suelo != "" and def.asset_muro_norte != "" \
		and def.asset_muro_oeste != "" and Assets.existe(def.asset_suelo) \
		and Assets.existe(def.asset_muro_norte) and Assets.existe(def.asset_muro_oeste)
	if not _arte_base_activo:
		return

	_arte_base = Node2D.new()
	_arte_base.name = "ArteBase"
	_arte_base.show_behind_parent = true
	add_child(_arte_base)

	var tex_suelo := Assets.textura(def.asset_suelo)
	var celda := Vector2(128, 64)
	var datos_suelo := Assets.datos(def.asset_suelo)
	if datos_suelo.has("celda_fisica"):
		var c: Array = datos_suelo["celda_fisica"]
		celda = Vector2(float(c[0]), float(c[1]))
	# El suelo visual incluye también las casillas perimetrales bajo los muros.
	# La transitabilidad continúa bloqueándolas; dibujarlas sólo evita que las
	# paredes parezcan flotar separadas del cuarto.
	for y in def.alto:
		for x in def.ancho:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex_suelo
			atlas.region = Rect2(((x + y) % 2) * celda.x, 0, celda.x, celda.y)
			var s := Sprite2D.new()
			s.texture = atlas
			s.position = Iso.centro(x, y)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_arte_base.add_child(s)

	# Las capas de decoración viven dentro del arte base para quedar siempre
	# detrás de actores. Su orden de hijos es deliberado: suelo decorado,
	# paredes y, finalmente, adornos colocados sobre esas paredes.
	_decoracion_suelo = Node2D.new()
	_decoracion_suelo.name = "DecoracionSuelo"
	_arte_base.add_child(_decoracion_suelo)

	for x in def.ancho:
		_montar_muro_asset(def.asset_muro_norte, Vector2i(x, 0))
	for y in range(1, def.alto):
		_montar_muro_asset(def.asset_muro_oeste, Vector2i(0, y))

	_decoracion_pared = Node2D.new()
	_decoracion_pared.name = "DecoracionPared"
	_arte_base.add_child(_decoracion_pared)

func _montar_muro_asset(clave: String, casilla: Vector2i) -> void:
	var s := Assets.sprite(clave)
	_arte_base.add_child(s)
	s.position = Iso.centro_v(casilla)

func _montar_muebles_visual(def: InteriorDefinicion) -> void:
	for m in def.muebles:
		var mueble: Dictionary = m
		if str(mueble.get("tipo", "")) == "cofre":
			continue
		if str(mueble.get("destino_zona", "")) != "":
			continue
		var clave := str(mueble.get("asset", ""))
		var interactuable := str(mueble.get("interactuable", ""))
		if clave == "" and interactuable == "":
			continue
		if clave != "" and not Assets.existe(clave) and interactuable == "":
			continue
		var soporte: Node2D
		match interactuable:
			"crafteo": soporte = EstacionCrafteoScript.new()
			"mercado": soporte = PuestoMercadoScript.new()
			"taberna": soporte = PuestoTabernaScript.new()
			_: soporte = Node2D.new()
		if soporte is Interactuable:
			(soporte as Interactuable).set_meta("estacion_id", str(mueble.get("estacion_id", def.tipo)))
			if soporte.has_method("set_estacion_id"):
				soporte.set_estacion_id(str(mueble.get("estacion_id", def.tipo)))
			if soporte.has_method("set_accion"):
				soporte.set_accion(str(mueble.get("accion", "Fabricar")))
			if soporte.has_method("set_horario_id"):
				soporte.set_horario_id(str(mueble.get("horario_id", "")))
			if soporte.has_method("set_actividades_productivas"):
				soporte.set_actividades_productivas(mueble.get("actividades_productivas", ["trabajar"]))
			if soporte.has_method("set_actividades_preparacion"):
				soporte.set_actividades_preparacion(mueble.get("actividades_preparacion", []))
		soporte.name = "Mueble_%s_%d_%d" % [str(mueble.get("tipo", "mueble")),
			_casilla_de(mueble).x, _casilla_de(mueble).y]
		soporte.position = _punto_anclaje(_casilla_de(mueble), _huella_de(mueble))
		_contenedor_para_capa(str(mueble.get("capa_visual", "mundo"))).add_child(soporte)
		if clave != "" and Assets.existe(clave):
			if Assets.es_placeholder(clave):
				var reemplazo := MuebleVisualScript.new()
				reemplazo.name = "VisualProvisional"
				reemplazo.configurar(str(mueble.get("tipo", "mueble")), _huella_de(mueble))
				soporte.add_child(reemplazo)
			else:
				var sprite := Assets.sprite(clave)
				soporte.add_child(sprite)
		if soporte is Interactuable:
			(soporte as Interactuable).establecer_casillas_interaccion(
				_casillas_de_acceso(_casilla_de(mueble), _huella_de(mueble)))

## Decide únicamente el orden visual. Transitabilidad y comportamiento siguen
## definidos por `solido`, `huella` y el tipo de objeto. Sin arte base modular,
## suelo y pared vuelven deliberadamente a Actores como respaldo visible.
func _contenedor_para_capa(capa: String) -> Node2D:
	match capa:
		"suelo":
			return _decoracion_suelo if _decoracion_suelo != null else actores
		"pared":
			return _decoracion_pared if _decoracion_pared != null else actores
		"efectos":
			if _efectos == null:
				_efectos = Node2D.new()
				_efectos.name = "Efectos"
				add_child(_efectos)
			return _efectos
		_:
			return actores

## Convierte cualquier mueble con `destino_zona` en un paso interactivo. Hoy
## es una escalera; mañana la misma pieza sirve para escotillas y pasadizos.
func _montar_transiciones(def: InteriorDefinicion) -> void:
	for m in def.muebles:
		var mueble: Dictionary = m
		var destino := str(mueble.get("destino_zona", ""))
		if destino == "":
			continue
		var casilla := _casilla_de(mueble)
		var t = TransicionZonaScript.new()
		t.name = "Mueble_%s_%d_%d" % [str(mueble.get("tipo", "paso")),
			casilla.x, casilla.y]
		t.casilla_propia = casilla
		t.destino_zona = destino
		var entrada: Variant = mueble.get("entrada_destino", Vector2i(1, 1))
		t.entrada_destino = entrada if entrada is Vector2i else Vector2i(1, 1)
		t.accion = str(mueble.get("accion", "Usar"))
		t.position = _punto_anclaje(casilla, _huella_de(mueble))
		t.usar_asset(str(mueble.get("asset", "")))
		t.establecer_casillas_interaccion(_casillas_de_acceso(casilla, _huella_de(mueble)))
		actores.add_child(t)
		t.atravesada.connect(func(transicion: Interactuable, quien: Node):
			transicion_solicitada.emit(transicion, quien))
		transiciones.append(t)

## Los muebles de tipo "cofre" dejan de ser decoración y pasan a ser objetos
## con identidad propia. Su contenido NO vive aquí: lo lleva `Contenedores`,
## indexado por instancia, para que sobreviva a salir y volver a entrar.
func _montar_cofres(def: InteriorDefinicion) -> void:
	if identidad == null:
		return
	for m in def.muebles:
		var mueble: Dictionary = m
		if str(mueble.get("tipo", "")) != "cofre":
			continue
		var casilla := _casilla_de(mueble)
		var definicion_cofre := str(mueble.get("definicion", "cofre_oxidado"))
		var c := Cofre.new()
		c.name = "Cofre_%d_%d" % [casilla.x, casilla.y]
		c.identidad = Entidades.identificar("objeto", definicion_cofre,
			"cofre:%s@%d,%d" % [identidad.instancia, casilla.x, casilla.y])
		c.contenido_inicial = (mueble.get("contenido", {}) as Dictionary).duplicate()
		c.asset_cerrado = str(mueble.get("asset_cerrado", ""))
		c.asset_abierto = str(mueble.get("asset_abierto", ""))
		c.zona_id = identidad.instancia
		c.casilla_interior = casilla
		c.position = _punto_anclaje(casilla, _huella_de(mueble))
		c.establecer_casillas_interaccion(_casillas_de_acceso(casilla, _huella_de(mueble)))
		actores.add_child(c)
		Entidades.vincular(c.identidad, c)
		c.abierto.connect(func(quien: Cofre): cofre_abierto.emit(quien))
		cofres.append(c)

func entrada() -> Vector2:
	return Vector2(definicion.entrada_valida()) + Vector2(0.5, 0.5)

func _casilla_de(mueble: Dictionary) -> Vector2i:
	var c: Variant = mueble.get("casilla", Vector2i.ZERO)
	return c if c is Vector2i else Vector2i.ZERO

func _huella_de(mueble: Dictionary) -> Vector2i:
	var h: Variant = mueble.get("huella", null)
	if h == null:
		var clave := str(mueble.get("asset", ""))
		if clave != "" and Assets.existe(clave):
			return Assets.huella(clave)
		h = Vector2i(1, 1)
	if h is Vector2i:
		return Vector2i(maxi(1, h.x), maxi(1, h.y))
	return Vector2i(1, 1)

func _casillas_de_acceso(origen: Vector2i, huella: Vector2i) -> Array[Vector2i]:
	var puntos: Array[Vector2i] = []
	var rejilla := transitable as TransitableRejilla
	var candidatos: Array[Vector2i] = []
	for dx in huella.x:
		candidatos.append(origen + Vector2i(dx, -1))
		candidatos.append(origen + Vector2i(dx, huella.y))
	for dy in huella.y:
		candidatos.append(origen + Vector2i(-1, dy))
		candidatos.append(origen + Vector2i(huella.x, dy))
	for candidato in candidatos:
		if rejilla == null or rejilla.puede_pisar(candidato):
			if candidato not in puntos:
				puntos.append(candidato)
	if puntos.is_empty():
		puntos.append(origen)
	return puntos

func _punto_anclaje(origen: Vector2i, huella: Vector2i) -> Vector2:
	if huella == Vector2i.ONE:
		return Iso.centro_v(origen)
	var apoyo := origen + huella - Vector2i.ONE
	return Iso.apoyo(apoyo.x, apoyo.y)

func _montar_puerta_salida(def: InteriorDefinicion, casilla_exterior: Vector2i,
		edificio_definicion: String, edificio_instancia: String) -> void:
	puerta_salida = Puerta.new()
	puerta_salida.name = "PuertaSalida"
	puerta_salida.sentido = Puerta.Sentido.SALIR
	puerta_salida.edificio_definicion = edificio_definicion
	puerta_salida.edificio_instancia = edificio_instancia
	puerta_salida.interior_id = def.id
	puerta_salida.casilla_exterior = casilla_exterior
	puerta_salida.casilla_propia = def.entrada_valida()
	puerta_salida.position = Iso.centro_v(puerta_salida.casilla_propia)
	if _decoracion_suelo != null:
		_decoracion_suelo.add_child(puerta_salida)
	else:
		add_child(puerta_salida)
		move_child(puerta_salida, actores.get_index())

# ---------------------------------------------------------------------------
# DIBUJO PROVISIONAL
# ---------------------------------------------------------------------------

func _draw() -> void:
	if definicion == null:
		return
	var tonos: Array = COLOR_SUELO.get(definicion.suelo, COLOR_SUELO["madera"])

	if not _arte_base_activo:
		# Suelo, en damero suave para que se lean las casillas.
		for y in definicion.alto:
			for x in definicion.ancho:
				if _es_muro(x, y):
					continue
				var c: Color = tonos[(x + y) % 2]
				_rombo(Iso.centro(x, y), c)

		# Muros del fondo: norte (y = 0) y oeste (x = 0).
		for x in definicion.ancho:
			_muro(Vector2i(x, 0))
		for y in range(1, definicion.alto):
			_muro(Vector2i(0, y))
	else:
		# Las esquinas transparentes de los tiles de piedra dejan ver el fondo
		# entre rombos. Cerramos sólo ese hueco con un tono cercano al suelo,
		# nunca con el color oscuro de la interfaz. Los PNG siguen dibujándose
		# encima y conservan sus bordes pixel-art.
		var base_suelo: Array = COLOR_SUELO.get(definicion.suelo, COLOR_SUELO["piedra"])
		var tono_juntas: Color = base_suelo[1].lightened(0.02)
		draw_colored_polygon(PackedVector2Array([
			Iso.centro(0, 0) + Vector2(0, -Iso.MEDIO_Y),
			Iso.centro(definicion.ancho - 1, 0) + Vector2(Iso.MEDIO_X, 0),
			Iso.centro(definicion.ancho - 1, definicion.alto - 1) + Vector2(0, Iso.MEDIO_Y),
			Iso.centro(0, definicion.alto - 1) + Vector2(-Iso.MEDIO_X, 0),
		]), tono_juntas)
	# Muebles como cajas de colores, hasta que haya sprites. Los cofres no:
	# esos se dibujan solos, porque son nodos con estado propio.
	for m in definicion.muebles:
		var mueble: Dictionary = m
		var tipo := str(mueble.get("tipo", "mueble"))
		if tipo == "cofre":
			continue
		var clave := str(mueble.get("asset", ""))
		if clave != "" and Assets.existe(clave) and not Assets.es_placeholder(clave):
			continue
		if clave != "" and Assets.es_placeholder(clave):
			continue # MuebleVisual ya reemplazó el placeholder técnico.
		_caja(_casilla_de(mueble), tipo)

func _es_muro(x: int, y: int) -> bool:
	return x == 0 or y == 0 or x == definicion.ancho - 1 or y == definicion.alto - 1

func _rombo(centro: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		centro + Vector2(0, -Iso.MEDIO_Y),
		centro + Vector2(Iso.MEDIO_X, 0),
		centro + Vector2(0, Iso.MEDIO_Y),
		centro + Vector2(-Iso.MEDIO_X, 0),
	]), color)

func _muro(casilla: Vector2i) -> void:
	var c := Iso.centro_v(casilla)
	var alto := Vector2(0, -ALTURA_MURO)
	var n := c + Vector2(0, -Iso.MEDIO_Y)
	var e := c + Vector2(Iso.MEDIO_X, 0)
	var s := c + Vector2(0, Iso.MEDIO_Y)
	var o := c + Vector2(-Iso.MEDIO_X, 0)
	draw_colored_polygon(PackedVector2Array([o + alto, s + alto, s, o]), COLOR_MURO)
	draw_colored_polygon(PackedVector2Array([s + alto, e + alto, e, s]),
		COLOR_MURO.lightened(0.10))
	draw_colored_polygon(PackedVector2Array([n + alto, e + alto, s + alto, o + alto]),
		COLOR_MURO_CIMA)

func _caja(casilla: Vector2i, tipo: String) -> void:
	var paleta := {
		"mesa": Color("8a6134"), "banco": Color("70502c"), "cama": Color("8d5a4a"),
		"barril": Color("6d4a24"), "chimenea": Color("6b6b6f"), "estanteria": Color("7a5a33"),
	}
	var color: Color = paleta.get(tipo, Color("7a6a4a"))
	var c := Iso.centro_v(casilla)
	var alto := Vector2(0, -22.0)
	var e := c + Vector2(Iso.MEDIO_X * 0.6, 0)
	var s := c + Vector2(0, Iso.MEDIO_Y * 0.6)
	var o := c + Vector2(-Iso.MEDIO_X * 0.6, 0)
	var n := c + Vector2(0, -Iso.MEDIO_Y * 0.6)
	draw_colored_polygon(PackedVector2Array([o + alto, s + alto, s, o]), color.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([s + alto, e + alto, e, s]), color.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([n + alto, e + alto, s + alto, o + alto]), color)
