extends Node
const AnimalScript := preload("res://scripts/mapa/animal.gd")

var correctas := 0
var fallos := 0
var animal

func _ready() -> void:
	Reloj.pausado = true
	AnimalesMundo.reiniciar()
	Entidades.reiniciar()
	var definicion: AnimalData = BaseDeDatos.animal("cerdo_salvaje")
	_comprobar("existe la definición del cerdo", definicion != null)
	_comprobar("la fauna conserva hábitat data-driven",
		definicion != null and definicion.habitat == "bosque")
	_comprobar("la fauna conserva parámetros de movimiento",
		definicion != null and definicion.velocidad > 0.0 and definicion.radio_deambular > 0.0)

	var rejilla := TransitableRejilla.new(10, 10)
	rejilla.amurallar()
	rejilla.liberar(Vector2i(4, 4))
	rejilla.liberar(Vector2i(5, 4))
	rejilla.bloquear(Vector2i(6, 4), "muro")
	animal = AnimalScript.new()
	add_child(animal)
	var montado: bool = bool(animal.montar("cerdo_salvaje", "isla:cerdo_salvaje@4,4", Vector2i(4, 4), rejilla, 7))
	_comprobar("monta un animal como entidad", montado)
	_comprobar("el animal hereda Actor", animal is Actor)
	_comprobar("el animal tiene identidad estable",
		animal.identidad != null and animal.identidad.tipo == "animal")
	_comprobar("el animal queda registrado en AnimalesMundo",
		AnimalesMundo.estado(animal.identidad.instancia).has("pos_tile"))
	_comprobar("el animal usa la transitabilidad común", animal.transitable == rejilla)
	animal.colocar(Vector2(5.5, 4.5))
	animal.mover(Vector2.RIGHT, 0.5)
	_comprobar("el animal no atraviesa una casilla bloqueada", animal.pos_tile.x <= 5.5)

	var identidad: Identidad = animal.get("identidad") as Identidad
	var id: String = identidad.instancia
	var estado_inicial := AnimalesMundo.estado(id)
	_comprobar("el estado del animal es plano",
		estado_inicial.get("pos_tile", {}) is Dictionary
		and estado_inicial.get("direccion", {}) is Dictionary)
	animal.pos_tile = Vector2(5.5, 4.5)
	AnimalesMundo.anotar(animal)
	var guardado := AnimalesMundo._serializar()
	animal.colocar(Vector2(2.5, 2.5))
	AnimalesMundo._cargar(guardado)
	_comprobar("carga posición del animal desde datos planos",
		animal.pos_tile.distance_to(Vector2(5.5, 4.5)) < 0.01)
	_comprobar("la identidad no cambia al cargar", animal.identidad.instancia == id)
	_comprobar("la sección de animales está guardable",
		"animales_mundo" in Guardado.secciones_activas())

	Reloj.hora = 2.0
	animal.actualizar(0.1, Actor.Detalle.CERCA)
	_comprobar("el animal no doméstico duerme de noche", animal.estado_animal == "dormir")
	Reloj.hora = 10.0
	animal.actualizar(0.1, Actor.Detalle.CERCA)
	_comprobar("el animal vuelve al ciclo diurno", animal.detalle != Actor.Detalle.DORMIDO)

	print("=== %d/%d comprobaciones de animales ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
