class_name Animal
extends Actor
## Entidad viva de fauna. La definición describe la especie; este nodo sólo
## encarna una instancia concreta y se mueve dentro de una Zona.

var definicion_id: String = ""
var definicion: AnimalData = null
var identidad: Identidad = null
var destino: Vector2 = Vector2.ZERO
var estado_animal: String = "idle" ## idle | caminar | comer | dormir
var _tiempo_decision := 0.0
var _rnd := RandomNumberGenerator.new()

func montar(p_definicion_id: String, clave_natural: String, casilla: Vector2i,
		p_transitable: Transitable = null, semilla: int = 1) -> bool:
	var datos := BaseDeDatos.animal(p_definicion_id)
	if datos == null:
		return false
	definicion_id = p_definicion_id
	definicion = datos
	identidad = Entidades.identificar("animal", p_definicion_id, clave_natural)
	Entidades.vincular(identidad, self)
	transitable = p_transitable
	velocidad = datos.velocidad
	huella = Huella.cuadrada(0.45)
	_rnd.seed = semilla
	pos_tile = Vector2(casilla) + Vector2(0.5, 0.5)
	destino = pos_tile
	_aplicar_posicion()
	_gestor_animales().call("registrar", self)
	queue_redraw()
	return true

func aplicar_estado(datos: Dictionary) -> void:
	var p: Variant = datos.get("pos_tile", {})
	if p is Dictionary:
		pos_tile = Vector2(float(p.get("x", pos_tile.x)), float(p.get("y", pos_tile.y)))
	var d: Variant = datos.get("direccion", {})
	if d is Dictionary:
		direccion = Vector2(float(d.get("x", direccion.x)), float(d.get("y", direccion.y)))
	var objetivo: Variant = datos.get("destino", {})
	if objetivo is Dictionary:
		destino = Vector2(float(objetivo.get("x", pos_tile.x)), float(objetivo.get("y", pos_tile.y)))
	estado_animal = str(datos.get("estado_animal", "idle"))
	estado = str(datos.get("estado", "idle"))
	_aplicar_posicion()
	queue_redraw()

func serializar() -> Dictionary:
	return {
		"definicion": definicion_id,
		"pos_tile": {"x": pos_tile.x, "y": pos_tile.y},
		"direccion": {"x": direccion.x, "y": direccion.y},
		"destino": {"x": destino.x, "y": destino.y},
		"estado": estado,
		"estado_animal": estado_animal,
	}

func actualizar(delta: float, _nivel: int) -> void:
	if definicion == null:
		return
	if Reloj.es_de_noche() and not definicion.domestico:
		estado_animal = "dormir"
		detalle = Detalle.DORMIDO
		estado = "sleep"
		_gestor_animales().call("anotar", self)
		return
	detalle = Detalle.CERCA
	if estado_animal == "dormir":
		estado_animal = "idle"
	_tiempo_decision -= delta
	if _tiempo_decision <= 0.0:
		_tiempo_decision = _rnd.randf_range(1.5, 3.5)
		if _rnd.randf() < 0.35:
			estado_animal = "comer"
			destino = pos_tile
		else:
			estado_animal = "caminar"
			destino = _destino_aleatorio()
	var distancia := destino - pos_tile
	if distancia.length() <= 0.08:
		estado_animal = "idle"
		estado = "idle"
	else:
		mover(distancia, delta)
		if estado == "andar":
			estado_animal = "caminar"
	_gestor_animales().call("anotar", self)

func _destino_aleatorio() -> Vector2:
	var radio := definicion.radio_deambular
	for _i in 8:
		var candidato := pos_tile + Vector2(
			_rnd.randf_range(-radio, radio), _rnd.randf_range(-radio, radio))
		if transitable == null or transitable.cabe_en(candidato, huella):
			return candidato
	return pos_tile

func _gestor_animales() -> Node:
	return get_node("/root/AnimalesMundo")

func _draw() -> void:
	var cuerpo := GlobalColors.PALETA["arena_madera"]
	var sombra := GlobalColors.PALETA["marron_profundo"]
	if definicion != null:
		match definicion.tipo:
			"plaga":
				cuerpo = GlobalColors.PALETA["gris_claro"]
			"utilidad":
				cuerpo = GlobalColors.PALETA["rojo_calido"]
			_:
				cuerpo = GlobalColors.PALETA["arena_madera"]
	draw_circle(Vector2(0, 3), 10.0, GlobalColors.con_alpha("vacio_abismal", 0.28))
		# Cuerpo pixelado provisional: el punto de anclaje sigue siendo el pie.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -10), Vector2(4, -14), Vector2(12, -7),
		Vector2(7, 1), Vector2(-6, 1),
	]), cuerpo)
	draw_circle(Vector2(8, -14), 5.0, cuerpo.lightened(0.12))
	draw_circle(Vector2(10, -15), 1.2, sombra)
	draw_line(Vector2(-5, 0), Vector2(-6, 5), sombra, 2.0)
	draw_line(Vector2(5, 0), Vector2(6, 5), sombra, 2.0)
	if definicion != null and definicion.id == "loro_vigia":
		draw_colored_polygon(PackedVector2Array([
			Vector2(-2, -11), Vector2(-15, -17), Vector2(-7, -5),
		]), GlobalColors.PALETA["verde_brillo"])
