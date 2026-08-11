extends Node
## AUTOLOAD: Assets
##
## La frontera entre la lógica y el arte. Ningún sistema del juego vuelve a
## escribir una ruta de archivo: pide una CLAVE —"edificio.kit_casa.cuerpo"— y
## recibe la pieza ya montada, con su pivote puesto y su filtro aplicado.
##
## Así, cambiar de arte es editar `manifiesto.json`. Y si mañana el pixel art
## sustituye a los renders actuales, la lógica no se entera.
##
## DOS REGLAS QUE VIENEN DE HABERNOS QUEMADO:
##
##  · El pivote se DECLARA en el manifiesto, nunca se deduce de la imagen.
##    Deducirlo del canal alfa fue lo que nos dio los edificios flotando.
##  · Si un archivo falta o no mide lo que dice, sale un RECUADRO MAGENTA y un
##    aviso. Nunca un `null` silencioso que revienta tres pantallas después.

signal problema(clave: String, motivo: String)

const RUTA_MANIFIESTO := "res://assets/kit_validacion/manifiesto.json"
const COLOR_FALTA := Color(1, 0, 1)

var base: String = ""
var defectos: Dictionary = {}

var _assets: Dictionary = {}          ## clave -> Dictionary del manifiesto
var _texturas: Dictionary = {}        ## clave -> Texture2D (caché)
var _placeholder_cache: Dictionary = {} ## clave -> bool
var _problemas: Array[String] = []

func _ready() -> void:
	cargar_manifiesto(RUTA_MANIFIESTO)

# ---------------------------------------------------------------------------
# CARGA
# ---------------------------------------------------------------------------

func cargar_manifiesto(ruta: String) -> bool:
	_assets.clear()
	_texturas.clear()
	_placeholder_cache.clear()
	_problemas.clear()

	if not FileAccess.file_exists(ruta):
		_anotar("(manifiesto)", "no existe %s" % ruta)
		return false
	var f := FileAccess.open(ruta, FileAccess.READ)
	var leido: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(leido) != TYPE_DICTIONARY:
		_anotar("(manifiesto)", "JSON inválido en %s" % ruta)
		return false

	var doc: Dictionary = leido
	base = str(doc.get("base", ""))
	defectos = doc.get("defectos", {})
	var lista: Dictionary = doc.get("assets", {})
	for clave in lista:
		_assets[str(clave)] = lista[clave]
	print("[Assets] %d claves desde %s" % [_assets.size(), ruta])
	return true

func existe(clave: String) -> bool:
	return _assets.has(clave)

func claves() -> Array:
	var l := _assets.keys()
	l.sort()
	return l

func datos(clave: String) -> Dictionary:
	return _assets.get(clave, {})

func ruta_de(clave: String) -> String:
	var d := datos(clave)
	if d.is_empty():
		return ""
	return base + str(d.get("archivo", ""))

# ---------------------------------------------------------------------------
# PIEZAS YA MONTADAS
# ---------------------------------------------------------------------------

func textura(clave: String) -> Texture2D:
	if _texturas.has(clave):
		return _texturas[clave]
	var d := datos(clave)
	if d.is_empty():
		_anotar(clave, "no está en el manifiesto")
		return _marcador(Vector2i(64, 64))
	var ruta := ruta_de(clave)
	if not ResourceLoader.exists(ruta):
		_anotar(clave, "falta el archivo %s" % ruta)
		return _marcador(_tam(d))
	var tex: Texture2D = load(ruta)
	if tex == null:
		_anotar(clave, "no se pudo cargar %s" % ruta)
		return _marcador(_tam(d))
	_texturas[clave] = tex
	return tex

## Pivote DECLARADO, en píxeles físicos desde la esquina superior izquierda.
func pivote(clave: String) -> Vector2:
	var d := datos(clave)
	return _a_vector(d.get("pivote", [0, 0]))

## Un Sprite2D listo: sin centrar, con el pivote descontado y el filtro puesto.
## Colocando el nodo en el punto de anclaje del mundo, el arte cae donde debe.
func sprite(clave: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura(clave)
	s.centered = false
	s.offset = -pivote(clave)
	s.z_index = 0                      ## nunca se salta la ordenación por Y
	_aplicar_filtro(s, clave)
	return s

## SpriteFrames con una animación por dirección: "walk_abajo", "idle_derecha"...
## Las claves son las mismas que devuelve `Actor.clave_animacion()`.
func animacion(clave: String, prefijo: String = "") -> SpriteFrames:
	var d := datos(clave)
	var marcos := SpriteFrames.new()
	marcos.remove_animation("default")
	if d.is_empty():
		_anotar(clave, "no está en el manifiesto")
		return marcos

	var tex := textura(clave)
	var fot := _a_vector(d.get("fotograma_fisico", [0, 0]))
	var n := int(d.get("fotogramas", 1))
	var dirs: Array = d.get("direcciones", ["abajo"])
	var nombre_base := prefijo if prefijo != "" else _sufijo(clave)

	for fila in dirs.size():
		var anim := "%s_%s" % [nombre_base, str(dirs[fila])]
		marcos.add_animation(anim)
		marcos.set_animation_speed(anim, float(d.get("fps", 8)))
		marcos.set_animation_loop(anim, bool(d.get("bucle", true)))
		for col in n:
			var trozo := AtlasTexture.new()
			trozo.atlas = tex
			trozo.region = Rect2(col * fot.x, fila * fot.y, fot.x, fot.y)
			marcos.add_frame(anim, trozo)
	return marcos

## StyleBoxTexture con los márgenes del manifiesto, para paneles y barras.
func caja(clave: String) -> StyleBoxTexture:
	var d := datos(clave)
	var sb := StyleBoxTexture.new()
	sb.texture = textura(clave)
	var m: Array = d.get("margenes", [0, 0, 0, 0])
	if m.size() >= 4:
		sb.texture_margin_left = float(m[0])
		sb.texture_margin_right = float(m[1])
		sb.texture_margin_top = float(m[2])
		sb.texture_margin_bottom = float(m[3])
	return sb

## Huella declarada, siempre rectangular: [ancho, alto] en casillas.
func huella(clave: String) -> Vector2i:
	var d := datos(clave)
	var h: Array = d.get("huella", [1, 1])
	if h.size() < 2:
		return Vector2i(1, 1)
	return Vector2i(int(h[0]), int(h[1]))

## Los primeros assets del kit se generaron con guías cyan y cruces magenta.
## Se detectan por sus píxeles, no por nombres de archivo: así un mod puede
## sustituir el PNG sin tocar código y el juego nunca mostrará una guía de
## validación como si fuera arte final.
func es_placeholder(clave: String) -> bool:
	if _placeholder_cache.has(clave):
		return _placeholder_cache[clave]
	var textura_actual := textura(clave)
	if textura_actual == null:
		_placeholder_cache[clave] = true
		return true
	var imagen := textura_actual.get_image()
	if imagen == null or imagen.is_empty():
		_placeholder_cache[clave] = false
		return false
	var cyan := 0
	var magenta := 0
	for y in imagen.get_height():
		for x in imagen.get_width():
			var p := imagen.get_pixel(x, y)
			if p.a < 0.5:
				continue
			if p.r < 0.25 and p.g > 0.75 and p.b > 0.75:
				cyan += 1
			elif p.r > 0.75 and p.g < 0.25 and p.b > 0.75:
				magenta += 1
			if cyan >= 2 and magenta >= 1:
				_placeholder_cache[clave] = true
				return true
	var resultado := cyan >= 2 and magenta >= 1
	_placeholder_cache[clave] = resultado
	return resultado

## Lo que el asset DECLARA sobre su luz. Vacío si no declara ninguna.
## Ojo: esto no enciende nada. Construir la PointLight2D y decidir cuándo se
## enciende es cosa de la lógica; el arte sólo dice que admite una.
func luz(clave: String) -> Dictionary:
	return datos(clave).get("luz", {})

func _aplicar_filtro(nodo: CanvasItem, clave: String) -> void:
	var f := str(datos(clave).get("filtro", defectos.get("filtro", "nearest")))
	# Se aplica POR NODO, no como ajuste global del proyecto: así el arte
	# fotorrealista que todavía queda no cambia de aspecto.
	nodo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if f == "nearest" \
		else CanvasItem.TEXTURE_FILTER_PARENT_NODE

# ---------------------------------------------------------------------------
# VALIDACIÓN
# ---------------------------------------------------------------------------

## Recorre el manifiesto entero y devuelve la lista de problemas. Vacía = todo
## bien. La usa `prueba_assets`; también se puede llamar al arrancar.
func validar() -> Array[String]:
	_problemas.clear()
	for clave in claves():
		var d := datos(clave)
		_validar_escala(clave, d)
		_validar_archivo(clave, d)
		_validar_pivote(clave, d)
		_validar_pareja(clave, d)
	return _problemas.duplicate()

func problemas() -> Array[String]:
	return _problemas.duplicate()

## Regla del kit: el PNG físico es exactamente el lógico multiplicado por la
## escala. Si no cuadra, el arte no está en la rejilla y se verá con píxeles
## de tamaños distintos mezclados.
func _validar_escala(clave: String, d: Dictionary) -> void:
	var e := int(d.get("escala_pixel", defectos.get("escala_pixel", 2)))
	if e <= 0:
		_anotar(clave, "escala_pixel inválida")
		return
	for par in [["tam_fisico", "tam_logico"], ["celda_fisica", "celda_logica"],
			["fotograma_fisico", "fotograma_logico"]]:
		if not d.has(par[0]) or not d.has(par[1]):
			continue
		var fis := _a_vector(d[par[0]])
		var log := _a_vector(d[par[1]])
		if fis != log * float(e):
			_anotar(clave, "%s %s no es %s × %d" % [par[0], fis, par[1], e])

func _validar_archivo(clave: String, d: Dictionary) -> void:
	var ruta := ruta_de(clave)
	if not ResourceLoader.exists(ruta):
		_anotar(clave, "falta el archivo %s" % ruta)
		return
	var tex: Texture2D = load(ruta)
	if tex == null:
		_anotar(clave, "no se pudo cargar %s" % ruta)
		return
	var real := Vector2(tex.get_width(), tex.get_height())
	var declarado := _tam_v(d)
	if declarado != Vector2.ZERO and real != declarado:
		_anotar(clave, "mide %s pero declara %s" % [real, declarado])

	match str(d.get("tipo", "")):
		"atlas_tile", "atlas_mascara":
			_validar_celdas(clave, d, tex)
		"animacion":
			_validar_animacion(clave, d, real)

## Las esquinas de cada celda tienen que ser transparentes. Es la trampa que
## nos dejó el suelo a cuadros: los PNG traían negro OPACO fuera del rombo y
## cada tile tapaba a sus vecinos.
func _validar_celdas(clave: String, d: Dictionary, tex: Texture2D) -> void:
	var celda := _a_vector(d.get("celda_fisica", [128, 64]))
	if celda.x <= 0 or celda.y <= 0:
		_anotar(clave, "celda_fisica inválida")
		return
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var cols := int(tex.get_width() / celda.x)
	var filas := int(tex.get_height() / celda.y)
	var sucias := 0
	for fila in filas:
		for col in cols:
			var ox := int(col * celda.x)
			var oy := int(fila * celda.y)
			for esquina in [Vector2i(1, 1), Vector2i(int(celda.x) - 2, 1),
					Vector2i(1, int(celda.y) - 2),
					Vector2i(int(celda.x) - 2, int(celda.y) - 2)]:
				if img.get_pixel(ox + esquina.x, oy + esquina.y).a > 0.02:
					sucias += 1
	if sucias > 0:
		_anotar(clave, "%d esquinas de celda NO son transparentes (rombo mal recortado)" % sucias)

func _validar_animacion(clave: String, d: Dictionary, real: Vector2) -> void:
	var fot := _a_vector(d.get("fotograma_fisico", [0, 0]))
	if fot.x <= 0 or fot.y <= 0:
		_anotar(clave, "fotograma_fisico inválido")
		return
	var n := int(d.get("fotogramas", 0))
	var dirs: Array = d.get("direcciones", [])
	if n <= 0 or dirs.is_empty():
		_anotar(clave, "faltan fotogramas o direcciones")
		return
	var esperado := Vector2(fot.x * n, fot.y * dirs.size())
	if real != esperado:
		_anotar(clave, "hoja de %s; con %d fotogramas × %d direcciones debería ser %s"
			% [real, n, dirs.size(), esperado])

func _validar_pivote(clave: String, d: Dictionary) -> void:
	if not d.has("pivote"):
		return
	var p := _a_vector(d["pivote"])
	var lim := _tam_v(d)
	if str(d.get("tipo", "")) == "animacion":
		lim = _a_vector(d.get("fotograma_fisico", [0, 0]))
	if lim == Vector2.ZERO:
		return
	if p.x < 0 or p.y < 0 or p.x > lim.x or p.y > lim.y:
		_anotar(clave, "pivote %s fuera del lienzo %s" % [p, lim])

## Cuerpo y tejado del mismo edificio tienen que compartir lienzo y pivote.
## Si difieren un píxel, el tejado baila al ocultarse y al volver.
func _validar_pareja(clave: String, d: Dictionary) -> void:
	var otra := str(d.get("pareja", ""))
	if otra == "":
		return
	if not existe(otra):
		_anotar(clave, "su pareja '%s' no está en el manifiesto" % otra)
		return
	var o := datos(otra)
	if _tam_v(d) != _tam_v(o):
		_anotar(clave, "lienzo distinto al de su pareja '%s'" % otra)
	if _a_vector(d.get("pivote", [0, 0])) != _a_vector(o.get("pivote", [0, 0])):
		_anotar(clave, "pivote distinto al de su pareja '%s'" % otra)

# ---------------------------------------------------------------------------

func _anotar(clave: String, motivo: String) -> void:
	var linea := "%s: %s" % [clave, motivo]
	if linea not in _problemas:
		_problemas.append(linea)
	push_warning("[Assets] " + linea)
	problema.emit(clave, motivo)

## Recuadro magenta con una X. Imposible confundirlo con arte de verdad.
func _marcador(tam: Vector2i) -> Texture2D:
	var w := maxi(8, tam.x)
	var h := maxi(8, tam.y)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(COLOR_FALTA.r, COLOR_FALTA.g, COLOR_FALTA.b, 0.75))
	for x in w:
		var y := int(float(x) / w * h)
		img.set_pixel(x, clampi(y, 0, h - 1), GlobalColors.get_color_vacio())
		img.set_pixel(x, clampi(h - 1 - y, 0, h - 1), GlobalColors.get_color_vacio())
	return ImageTexture.create_from_image(img)

func _tam(d: Dictionary) -> Vector2i:
	var v := _tam_v(d)
	return Vector2i(int(v.x), int(v.y))

func _tam_v(d: Dictionary) -> Vector2:
	return _a_vector(d.get("tam_fisico", [0, 0]))

func _a_vector(crudo: Variant) -> Vector2:
	if typeof(crudo) != TYPE_ARRAY:
		return Vector2.ZERO
	var a: Array = crudo
	if a.size() < 2:
		return Vector2.ZERO
	return Vector2(float(a[0]), float(a[1]))

func _sufijo(clave: String) -> String:
	var partes := clave.split(".")
	return partes[partes.size() - 1]
