class_name EdificioVisual
extends Node2D
## El edificio en pantalla, atado a su EstacionTrabajo.
##
## Aquí es donde la logística se vuelve visible: si a la herrería le falta
## acero, se ve en el mapa —cartel rojo y sin humo— sin abrir ningún menú.

## Los 5 renders disponibles, con el punto exacto donde cada uno apoya en el
## suelo (medido del canal alfa de las versiones sin sombra) y cuántas casillas
## ocupa. Un edificio mal anclado flota o se hunde; estos números lo evitan.
const MODELOS := {
	"casa_a":    { "lienzo": 640,  "apoyo": Vector2(284.5, 627.0),  "lado": 4 },
	"casa_b":    { "lienzo": 896,  "apoyo": Vector2(498.0, 875.0),  "lado": 5 },
	"casa_c":    { "lienzo": 768,  "apoyo": Vector2(383.5, 720.0),  "lado": 5 },
	"caseron":   { "lienzo": 1024, "apoyo": Vector2(405.0, 1010.0), "lado": 6 },
	"cobertizo": { "lienzo": 512,  "apoyo": Vector2(266.5, 428.0),  "lado": 3 },
}

var edificio_id: String = ""             ## qué es: "taberna"
var identidad: Identidad                 ## cuál es: "edificio_0007"
var modelo: String = "casa_a"
## Huella rectangular en casillas. `lado` se conserva por compatibilidad con el
## código que ya existe y siempre vale `huella.x`.
var huella: Vector2i = Vector2i(4, 4)
var tejado: Sprite2D = null              ## sólo en edificios montados desde el kit
var angulo: int = 0
var casilla := Vector2i.ZERO
var lado: int = 4
var estaciones: Array[EstacionTrabajo] = []

var _sprite: Sprite2D
var _cartel: Node2D
var _humo: GPUParticles2D
var _parado := false
var _resaltado := false

func montar(p_edificio: String, p_modelo: String, p_casilla: Vector2i, p_angulo: int) -> void:
	edificio_id = p_edificio
	modelo = p_modelo if MODELOS.has(p_modelo) else "casa_a"
	casilla = p_casilla
	# 00–03 son las rotaciones; 04–07 son las mismas con nieve. Nunca pasar de 3.
	angulo = p_angulo % 4
	lado = int(MODELOS[modelo]["lado"])
	huella = Vector2i(lado, lado)

	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/edificios/%s_%02d.png" % [modelo, angulo])
	_sprite.centered = false
	# El sprite se coloca de modo que su punto de apoyo caiga en el vértice
	# inferior del cuadrado de casillas que ocupa el edificio.
	_sprite.offset = -MODELOS[modelo]["apoyo"]
	add_child(_sprite)

	position = Iso.apoyo_bloque(casilla.x, casilla.y, lado)
	# Los objetos se ordenan por su Y: el que está más abajo tapa al de arriba.
	y_sort_enabled = false
	z_index = 0

	_montar_humo()
	_montar_cartel()

func _montar_humo() -> void:
	var apoyo: Vector2 = MODELOS[modelo]["apoyo"]
	_humo = GPUParticles2D.new()
	_humo.amount = 10
	_humo.lifetime = 5.0
	# A la altura del caballete y un poco hacia la chimenea.
	_humo.position = Vector2(apoyo.x * 0.12, -apoyo.y * 0.66)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.35, -1, 0)
	mat.spread = 14.0
	mat.initial_velocity_min = 18.0
	mat.initial_velocity_max = 34.0
	mat.gravity = Vector3(10, -20, 0)
	# Bocanadas grandes y translúcidas. Con partículas pequeñas y opacas el
	# humo parecía un punto de pintura blanca sobre el tejado.
	mat.scale_min = 5.0
	mat.scale_max = 13.0
	var rampa := Gradient.new()
	rampa.set_color(0, Color(0.62, 0.61, 0.58, 0.30))
	rampa.set_color(1, Color(0.70, 0.70, 0.68, 0.0))
	var tex_rampa := GradientTexture1D.new()
	tex_rampa.gradient = rampa
	mat.color_ramp = tex_rampa
	_humo.process_material = mat
	_humo.texture = _punto_suave()
	_humo.emitting = false
	add_child(_humo)

func _montar_cartel() -> void:
	_cartel = Node2D.new()
	_cartel.position = Vector2(0, -MODELOS[modelo]["apoyo"].y * 0.95)
	_cartel.z_index = 10
	_cartel.visible = false
	add_child(_cartel)
	var etiqueta := Label.new()
	etiqueta.name = "Texto"
	etiqueta.add_theme_font_size_override("font_size", 22)
	etiqueta.add_theme_color_override("font_color", GlobalColors.color("luz_palida"))
	etiqueta.add_theme_color_override("font_outline_color",
		GlobalColors.con_alpha("vacio_abismal", 0.9))
	etiqueta.add_theme_constant_override("outline_size", 8)
	etiqueta.position = Vector2(-90, -30)
	etiqueta.custom_minimum_size = Vector2(180, 0)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cartel.add_child(etiqueta)

func _punto_suave() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length() / 8.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)

# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	var trabajando := false
	var parada := false
	for e in estaciones:
		if e.parada:
			parada = true
		elif e.estado_texto() == "produciendo":
			trabajando = true

	if _humo != null and _humo.emitting != trabajando:
		_humo.emitting = trabajando

	if parada != _parado:
		_parado = parada
		_cartel.visible = parada
		if parada:
			var motivo := "parada"
			for e in estaciones:
				if e.parada and e.ultimo_motivo != "":
					motivo = e.ultimo_motivo
					break
			_texto_cartel("⚠ " + motivo)
		_sprite.modulate = Color(1.0, 0.86, 0.86) if parada else Color.WHITE

	# Un parpadeo lento cuando está parada: se ve desde lejos sin ser molesto.
	if _parado:
		var pulso := 0.65 + 0.35 * sin(Time.get_ticks_msec() / 260.0)
		_cartel.modulate = Color(1, 1, 1, pulso)

func _texto_cartel(t: String) -> void:
	var etiqueta := _cartel.get_node_or_null("Texto") as Label
	if etiqueta != null:
		etiqueta.text = t

## Monta el edificio desde el MANIFIESTO en vez de desde rutas escritas a mano.
## Es la vía nueva: cuerpo y tejado son piezas separadas, el pivote lo declara
## el manifiesto y la huella puede ser rectangular.
##
## `montar()` sigue existiendo intacto para el arte actual: las dos vías
## conviven, que es justo lo que hay que demostrar.
func montar_kit(p_edificio_id: String, clave_base: String, p_casilla: Vector2i) -> void:
	edificio_id = p_edificio_id
	casilla = p_casilla
	huella = Assets.huella(clave_base + ".cuerpo")
	lado = huella.x

	# Una sola unidad dentro del contenedor ordenado por Y: el nodo no ordena
	# a sus hijos, así que cuerpo y tejado viajan juntos y comparten su Y.
	y_sort_enabled = false
	z_index = Capas.MUNDO

	_sprite = Assets.sprite(clave_base + ".cuerpo")
	_sprite.name = "Cuerpo"
	Capas.colocar(self, _sprite, Capas.HIJO_CUERPO)

	if Assets.existe(clave_base + ".tejado"):
		tejado = Assets.sprite(clave_base + ".tejado")
		tejado.name = "Tejado"
		Capas.colocar(self, tejado, Capas.HIJO_TEJADO)

	# El vértice inferior de la huella. Con huella rectangular no vale
	# `apoyo_bloque`, que asume cuadrado; se calcula sin tocar Iso.
	position = Iso.apoyo(casilla.x + huella.x - 1, casilla.y + huella.y - 1)

## Ocultar el tejado al entrar es sólo esto, porque cuerpo y tejado comparten
## lienzo y pivote: no hay nada que recolocar.
func mostrar_tejado(visible_ahora: bool) -> void:
	if tejado != null:
		tejado.visible = visible_ahora

func tejado_visible() -> bool:
	return tejado != null and tejado.visible

## Evita que un tejado en primer plano esconda al jugador. Los edificios del
## kit atenúan sólo su tejado separable; los renders antiguos aún son una sola
## imagen y se atenúan completos. No cambia colisiones, profundidad ni estado.
func actualizar_occlusion(punto_global: Vector2) -> void:
	var pieza := tejado if tejado != null else _sprite
	if pieza == null:
		return
	var detras := punto_global.y < global_position.y
	var dentro_del_lienzo := pieza.get_rect().has_point(pieza.to_local(punto_global))
	var alpha := 0.28 if detras and dentro_del_lienzo else 1.0
	if tejado != null:
		tejado.self_modulate.a = alpha
	else:
		_sprite.self_modulate.a = alpha

## Sólo para depurar el aspecto: quita el humo del tejado.
func apagar_humo() -> void:
	if _humo != null:
		_humo.emitting = false
		_humo.visible = false
		_humo.queue_free()
		_humo = null

func resaltar(activo: bool) -> void:
	if _resaltado == activo:
		return
	_resaltado = activo
	_sprite.modulate = Color(1.15, 1.12, 1.0) if activo else \
		(Color(1.0, 0.86, 0.86) if _parado else Color.WHITE)

func nombre() -> String:
	var e: EdificioData = BaseDeDatos.edificio(edificio_id)
	return e.nombre if e != null else edificio_id

## ¿Cae este punto del mundo sobre el sprite del edificio?
func contiene(p: Vector2) -> bool:
	var m: Dictionary = MODELOS[modelo]
	var apoyo: Vector2 = m["apoyo"]
	var local: Vector2 = p - position + apoyo
	var lienzo: float = m["lienzo"]
	return local.x >= 0 and local.y >= 0 and local.x < lienzo and local.y < lienzo
