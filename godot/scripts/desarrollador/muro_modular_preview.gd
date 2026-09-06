extends Node2D
class_name MuroModularPreview

const COLOR_MORTERO := Color("#0f0f1b")
const COLOR_PIEDRA_OSCURA := Color("#26303e")

var interior: Node2D
var ancho: int = 10
var alto: int = 8
var altura_fisica: float = 128.0
var mostrar_guias: bool = true
var textura_piedra: Texture2D = null

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var ruta := ProjectSettings.globalize_path("res://assets/kit_validacion/interiores/arte/herreria/herreria_batch05_textura_piedra_preview.png")
	var imagen := Image.load_from_file(ruta)
	if imagen != null and not imagen.is_empty():
		textura_piedra = ImageTexture.create_from_image(imagen)
	queue_redraw()

func configurar(zona: Node2D, ancho_zona: int, alto_zona: int) -> void:
	interior = zona
	ancho = maxi(ancho_zona, 1)
	alto = maxi(alto_zona, 1)
	queue_redraw()

func _draw() -> void:
	if interior == null or not is_instance_valid(interior):
		return
	_dibujar_arista(Vector2i(0, 0), Vector2(64.0, 32.0), ancho)
	_dibujar_arista(Vector2i(0, 0), Vector2(-64.0, 32.0), alto)
	if mostrar_guias:
		_dibujar_guias()

func _ancla_global(casilla: Vector2i) -> Vector2:
	return interior.to_global(Iso.centro_v(casilla) + Vector2(0.0, -Iso.MEDIO_Y))

func _punto_local(global_pos: Vector2) -> Vector2:
	return to_local(global_pos)

func _punto_muro(inicio: Vector2, direccion: Vector2, longitud: int, u: float, v: float) -> Vector2:
	return inicio + direccion * (u * float(longitud)) + Vector2(0.0, -altura_fisica * v)

func _dibujar_arista(inicio_tile: Vector2i, direccion: Vector2, longitud: int) -> void:
	var inicio := _punto_local(_ancla_global(inicio_tile))
	var fin := inicio + direccion * float(longitud)
	var arriba_inicio := inicio + Vector2(0.0, -altura_fisica)
	var arriba_fin := fin + Vector2(0.0, -altura_fisica)

	# Prueba artística: la textura se proyecta únicamente dentro del
	# cuadrilátero mural. Los cuatro vértices siguen siendo los ejes Iso exactos.
	if textura_piedra != null:
		var quad := PackedVector2Array([inicio, fin, arriba_fin, arriba_inicio])
		var uvs := PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(1.0, 0.0),
			Vector2(1.0, 1.0), Vector2(0.0, 1.0)
		])
		var tintes := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
		draw_polygon(quad, tintes, uvs, textura_piedra)
		draw_line(arriba_inicio, arriba_fin, Color("#aab1ba", 0.78), 3.0)
		draw_line(inicio, fin, COLOR_MORTERO, 2.0)
		return

	# Fondo de mortero continuo. La geometria siempre conserva el eje 2:1.
	draw_colored_polygon(PackedVector2Array([inicio, fin, arriba_fin, arriba_inicio]), COLOR_MORTERO)

	# Piedras grandes y variadas: menos piezas, juntas gruesas y sin patrón de
	# tablero. Todas las coordenadas se interpolan dentro del plano mural.
	var patrones: Array = [
		[0.0, 0.22, 0.48, 0.76, 1.0],
		[0.0, 0.16, 0.40, 0.66, 0.86, 1.0],
		[0.0, 0.28, 0.55, 0.79, 1.0],
		[0.0, 0.18, 0.43, 0.70, 1.0],
		[0.0, 0.24, 0.50, 0.72, 0.88, 1.0]
	]
	var colores: Array[Color] = [
		Color("#4c5868"),
		Color("#5e6876"),
		Color("#707987"),
		Color("#596474")
	]
	var filas: int = patrones.size()
	for fila in range(filas):
		var t0 := float(fila) / float(filas)
		var t1 := float(fila + 1) / float(filas)
		var puntos: Array = patrones[fila]
		for piedra in range(puntos.size() - 1):
			var u0 := float(puntos[piedra])
			var u1 := float(puntos[piedra + 1])
			var margen_u := minf(0.010, (u1 - u0) * 0.18)
			var margen_v := 0.014
			var p0 := _punto_muro(inicio, direccion, longitud, u0 + margen_u, t0 + margen_v)
			var p1 := _punto_muro(inicio, direccion, longitud, u1 - margen_u, t0 + margen_v)
			var p2 := _punto_muro(inicio, direccion, longitud, u1 - margen_u, t1 - margen_v)
			var p3 := _punto_muro(inicio, direccion, longitud, u0 + margen_u, t1 - margen_v)
			var color: Color = colores[(fila * 3 + piedra * 2) % colores.size()]
			draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), color)
			draw_line(p3, p2, Color("#9aa2ad", 0.32), 1.5)
			draw_line(p0, p1, Color("#18202d", 0.78), 1.5)

	# Remates continuos, sin coronas ni postes repetidos.
	draw_line(arriba_inicio, arriba_fin, Color("#9aa2ad", 0.82), 3.0)
	draw_line(inicio, fin, COLOR_MORTERO, 2.0)

func _dibujar_guias() -> void:
	var inicio_x := _punto_local(_ancla_global(Vector2i(0, 0)))
	var fin_x := inicio_x + Vector2(64.0, 32.0) * float(ancho)
	var inicio_y := inicio_x
	var fin_y := inicio_y + Vector2(-64.0, 32.0) * float(alto)
	var guia := Color("#c2c2d1", 0.75)
	draw_polyline(PackedVector2Array([inicio_x, fin_x]), guia, 2.0)
	draw_polyline(PackedVector2Array([inicio_y, fin_y]), guia, 2.0)
	draw_circle(inicio_x, 4.0, guia)
	draw_circle(fin_x, 4.0, guia)
	draw_circle(fin_y, 4.0, guia)
