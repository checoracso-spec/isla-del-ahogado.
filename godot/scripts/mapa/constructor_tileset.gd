class_name ConstructorTileset
extends RefCounted
## Construye el TileSet isométrico leyendo los PNG de assets/tiles/.
##
## Lo interesante está en las hojas de transición ("Grass A to Sand A",
## "Sand A - Water Flat"). Son rejillas de rombos donde cada rombo mezcla dos
## terrenos, uno en cada esquina. Nadie documenta qué rombo es cuál, así que
## en vez de escribir una tabla a mano de 48 casillas —y equivocarme— el código
## MIRA cada rombo: muestrea sus cuatro vértices, decide si cada uno es terreno
## A o B, y con eso arma una máscara de 4 bits.
##
## Luego, al pintar la isla, se calcula la misma máscara a partir de las
## esquinas reales del mapa y se busca el rombo que encaje. Las playas y las
## orillas salen solas.

const RUTA := "res://assets/tiles/"

# Niveles de terreno. Sólo pueden tocarse niveles consecutivos: entre hierba
# y agua SIEMPRE tiene que haber arena. El generador se encarga de forzarlo.
## AGUA/ARENA/HIERBA son niveles del terreno y sólo pueden tocarse consecutivos.
## TIERRA va aparte: es una superficie que se pinta ENCIMA de la hierba (la
## explanada pisoteada del pueblo), con sus propias transiciones.
enum { AGUA = 0, ARENA = 1, HIERBA = 2, TIERRA = 3, HIERBA_B = 4 }

var tileset: TileSet

## nivel -> { "fuente": id, "celdas": [Vector2i] }   rombos puros
var puros: Dictionary = {}
## "menor|mayor" -> { "fuente": id, "mascaras": { int -> [Vector2i] } }
var transiciones: Dictionary = {}
## decorados sueltos que se pintan en su propia capa
var fuente_bosque: int = -1
var celdas_bosque: Array[Vector2i] = []
var fuente_adoquin: int = -1
var celda_adoquin: Vector2i = Vector2i.ZERO
var fuente_roca: int = -1
var celdas_roca: Array[Vector2i] = []

var _aleatorio := RandomNumberGenerator.new()

func construir(semilla: int = 0) -> TileSet:
	_aleatorio.seed = semilla

	tileset = TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tileset.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	tileset.tile_size = Vector2i(Iso.ANCHO, Iso.ALTO)

	# --- terrenos puros ---
	# base.png = "Solid Tiles Flat", 6 rombos:
	#   0 hierba A · 1 hierba B · 2 tierra A · 3 tierra B · 4 arena · 5 agua
	var base_tex := _cargar("base.png")
	var base_id := _anadir_fuente(base_tex, Vector2i(Iso.ANCHO, Iso.ALTO))
	var ref_hierba := _color_medio(base_tex, Vector2i(0, 0))
	var ref_arena := _color_medio(base_tex, Vector2i(4, 0))
	var ref_agua := _color_medio(base_tex, Vector2i(5, 0))
	var ref_tierra := _color_medio(base_tex, Vector2i(2, 0))
	puros[HIERBA] = { "fuente": base_id, "celdas": [Vector2i(0, 0)] }
	puros[HIERBA_B] = { "fuente": base_id, "celdas": [Vector2i(1, 0)] }
	puros[ARENA] = { "fuente": base_id, "celdas": [Vector2i(4, 0)] }
	puros[AGUA] = { "fuente": base_id, "celdas": [Vector2i(5, 0)] }
	puros[TIERRA] = { "fuente": base_id, "celdas": [Vector2i(2, 0), Vector2i(3, 0)] }

	# --- transiciones ---
	_leer_transicion("trans_arena_agua.png", ARENA, AGUA, ref_arena, ref_agua)
	_leer_transicion("trans_hierba_arena.png", HIERBA, ARENA, ref_hierba, ref_arena)
	_leer_transicion("trans_hierba_tierra.png", HIERBA, TIERRA, ref_hierba, ref_tierra)

	# --- decorados ---
	var bosque_tex := _cargar("bosque.png")
	fuente_bosque = _anadir_fuente(bosque_tex, Vector2i(Iso.ANCHO, Iso.ALTO))
	celdas_bosque = _celdas_llenas(bosque_tex, Vector2i(Iso.ANCHO, Iso.ALTO))

	var roca_tex := _cargar("roca.png")
	fuente_roca = _anadir_fuente(roca_tex, Vector2i(Iso.ANCHO, Iso.ALTO))
	celdas_roca = _celdas_llenas(roca_tex, Vector2i(Iso.ANCHO, Iso.ALTO))

	# El adoquín viene en 128×72: 8 px más alto porque tiene borde levantado.
	# Se sube 4 px para que el rombo del suelo caiga donde debe.
	var adoquin_tex := _cargar("adoquin.png")
	fuente_adoquin = _anadir_fuente(adoquin_tex, Vector2i(128, 72), Vector2i(0, -4))
	celda_adoquin = Vector2i(1, 0)      # 0 es una rejilla de ciencia ficción; el 1 es la piedra

	return tileset

# ---------------------------------------------------------------------------
# LECTURA DE UNA HOJA DE TRANSICIÓN
# ---------------------------------------------------------------------------

func _leer_transicion(archivo: String, nivel_a: int, nivel_b: int,
		ref_a: Color, ref_b: Color) -> void:
	var tex := _cargar(archivo)
	if tex == null:
		return
	var img := _imagen(tex)
	var fuente := _anadir_fuente(tex, Vector2i(Iso.ANCHO, Iso.ALTO))

	var cols := int(img.get_width() / Iso.ANCHO)
	var filas := int(img.get_height() / Iso.ALTO)
	var mascaras: Dictionary = {}

	for cy in filas:
		for cx in cols:
			var celda := Vector2i(cx, cy)
			var muestras := _muestrear_vertices(img, celda)
			if muestras.is_empty():
				continue                       # rombo vacío: hueco de la hoja
			var mascara := 0
			for i in 4:
				var c: Color = muestras[i]
				if _distancia(c, ref_b) < _distancia(c, ref_a):
					mascara |= 1 << i
			if not mascaras.has(mascara):
				mascaras[mascara] = []
			mascaras[mascara].append(celda)

	transiciones[_clave(nivel_a, nivel_b)] = {
		"fuente": fuente,
		"mascaras": mascaras,
		"nivel_b": nivel_b,
	}

## Muestrea los cuatro vértices del rombo. Devuelve [] si el rombo está vacío.
## Orden: arriba, derecha, abajo, izquierda (el mismo que Iso.esquinas).
func _muestrear_vertices(img: Image, celda: Vector2i) -> Array:
	var ox := celda.x * Iso.ANCHO
	var oy := celda.y * Iso.ALTO
	var puntos := [
		Vector2i(64, 12),      # arriba
		Vector2i(104, 32),     # derecha
		Vector2i(64, 52),      # abajo
		Vector2i(24, 32),      # izquierda
	]
	var res := []
	for p: Vector2i in puntos:
		var suma := Color(0, 0, 0, 0)
		var n := 0
		for dy in range(-5, 6, 2):
			for dx in range(-9, 10, 3):
				var px := ox + p.x + dx
				var py := oy + p.y + dy
				if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
					continue
				var c := img.get_pixel(px, py)
				if c.a < 0.5:
					continue
				suma += c
				n += 1
		if n < 4:
			return []                          # vértice transparente -> rombo vacío
		res.append(Color(suma.r / n, suma.g / n, suma.b / n, 1.0))
	return res

func _distancia(a: Color, b: Color) -> float:
	# Distancia con algo más de peso en el azul: separa bien agua de arena.
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := (a.b - b.b) * 1.4
	return dr * dr + dg * dg + db * db

# ---------------------------------------------------------------------------
# CONSULTA (la usa el generador de la isla)
# ---------------------------------------------------------------------------

## Devuelve [fuente, celda] para un tile cuyas 4 esquinas tienen estos niveles.
## `niveles` va en el orden arriba, derecha, abajo, izquierda.
func resolver(niveles: Array) -> Array:
	var menor: int = niveles.min()
	var mayor: int = niveles.max()

	if menor == mayor:
		return _puro(menor)

	if mayor - menor > 1:
		# No debería pasar: el generador intercala arena. Si pasa, algo mejor
		# que un agujero en el mapa.
		return _puro(menor + 1)

	var t: Dictionary = transiciones.get(_clave(menor, mayor), {})
	if t.is_empty():
		return _puro(menor)

	var mascara := 0
	for i in 4:
		if int(niveles[i]) == int(t["nivel_b"]):
			mascara |= 1 << i

	var lista: Array = t["mascaras"].get(mascara, [])
	if lista.is_empty():
		return _puro(menor)
	return [t["fuente"], lista[_aleatorio.randi() % lista.size()]]

func _puro(nivel: int) -> Array:
	var p: Dictionary = puros.get(nivel, {})
	if p.is_empty():
		return [-1, Vector2i.ZERO]
	var celdas: Array = p["celdas"]
	return [p["fuente"], celdas[_aleatorio.randi() % celdas.size()]]

## Rombo puro de un terreno concreto, sin sorteo. Lo usa el generador cuando
## quiere elegir él la variante (para que la hierba no salga a cuadros).
func puro_de(nivel: int) -> Array:
	var p: Dictionary = puros.get(nivel, {})
	if p.is_empty():
		return [-1, Vector2i.ZERO]
	return [p["fuente"], p["celdas"][0]]

func celda_al_azar(celdas: Array[Vector2i]) -> Vector2i:
	if celdas.is_empty():
		return Vector2i.ZERO
	return celdas[_aleatorio.randi() % celdas.size()]

# ---------------------------------------------------------------------------
# AYUDAS
# ---------------------------------------------------------------------------

func _clave(a: int, b: int) -> String:
	return "%d|%d" % [mini(a, b), maxi(a, b)]

func _cargar(archivo: String) -> Texture2D:
	var ruta := RUTA + archivo
	if not ResourceLoader.exists(ruta):
		push_error("Falta el tile: " + ruta)
		return null
	return load(ruta)

## La textura importada puede venir comprimida para la GPU; hay que
## descomprimirla antes de leer píxeles uno a uno.
func _imagen(tex: Texture2D) -> Image:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img

func _color_medio(tex: Texture2D, celda: Vector2i) -> Color:
	var img := _imagen(tex)
	var suma := Color(0, 0, 0, 0)
	var n := 0
	for dy in range(20, 45, 3):
		for dx in range(40, 90, 4):
			var c := img.get_pixel(celda.x * Iso.ANCHO + dx, celda.y * Iso.ALTO + dy)
			if c.a < 0.5:
				continue
			suma += c
			n += 1
	if n == 0:
		return Color.MAGENTA
	return Color(suma.r / n, suma.g / n, suma.b / n, 1.0)

func _anadir_fuente(tex: Texture2D, region: Vector2i, origen := Vector2i.ZERO) -> int:
	if tex == null:
		return -1
	var fuente := TileSetAtlasSource.new()
	fuente.texture = tex
	fuente.texture_region_size = region
	var cols := int(tex.get_width() / region.x)
	var filas := int(tex.get_height() / region.y)
	for y in filas:
		for x in cols:
			var celda := Vector2i(x, y)
			fuente.create_tile(celda)
			if origen != Vector2i.ZERO:
				fuente.get_tile_data(celda, 0).texture_origin = origen
	return tileset.add_source(fuente)

## Celdas de una hoja que no están vacías (las hojas traen huecos negros).
func _celdas_llenas(tex: Texture2D, region: Vector2i) -> Array[Vector2i]:
	var res: Array[Vector2i] = []
	if tex == null:
		return res
	var img := _imagen(tex)
	var cols := int(tex.get_width() / region.x)
	var filas := int(tex.get_height() / region.y)
	for y in filas:
		for x in cols:
			var c := img.get_pixel(x * region.x + region.x / 2, y * region.y + region.y / 2)
			if c.a > 0.5:
				res.append(Vector2i(x, y))
	return res
