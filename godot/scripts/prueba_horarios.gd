extends Node
## Prueba del primer horario data-driven de la tripulación.

var fallos := 0
var pruebas := 0
var pirata: Pirata

func _ready() -> void:
	print("\n=== PRUEBAS DE HORARIOS ===\n")
	Reloj.pausado = true
	Motin.nivel = 0.0
	var horario := BaseDeDatos.horario("tripulacion")
	_comprobar("existe el horario", horario != null)
	var herrero: HorarioData = BaseDeDatos.horario("herrero")
	var barbanegra: PersonajeData = BaseDeDatos.personaje("barbanegra")
	_comprobar("existe el horario del herrero", herrero != null)
	_comprobar("Barbanegra usa el horario del herrero",
		barbanegra != null and barbanegra.horario_id == "herrero")
	_comprobar("Barbanegra declara puesto y casa en datos",
		barbanegra != null and barbanegra.puesto_id == "herreria"
		and barbanegra.casa_id == "cabana_capitan")
	_comprobar("PersonajeData declara carga inicial opcional",
		barbanegra != null and barbanegra.inventario_inicial.get("ron", 0) == 1
		and barbanegra.oro_inicial == 25)
	if horario != null:
		_comprobar("02:00 dormir", horario.actividad_en(2.0) == "dormir")
		_comprobar("07:30 casa", horario.actividad_en(7.5) == "casa")
		_comprobar("09:00 trabajar", horario.actividad_en(9.0) == "trabajar")
		_comprobar("12:30 comer", horario.actividad_en(12.5) == "comer")
		_comprobar("14:00 trabajar", horario.actividad_en(14.0) == "trabajar")
		_comprobar("19:00 pasear", horario.actividad_en(19.0) == "pasear")
		_comprobar("21:00 taberna", horario.actividad_en(21.0) == "taberna")
		_comprobar("23:00 dormir", horario.actividad_en(23.0) == "dormir")
		_comprobar("hora fuera de rango usa paseo", horario.actividad_en(25.0) == "pasear")
	if herrero != null:
		_comprobar("el herrero trabaja a las 07:30", herrero.actividad_en(7.5) == "trabajar")
		_comprobar("el herrero esta en casa a las 19:00", herrero.actividad_en(19.0) == "casa")

	var estacion := EstacionTrabajo.new()
	estacion.horario_id = "herrero"
	_comprobar("la herreria produce a las 07:30", estacion.en_horario(7.5))
	_comprobar("la herreria se detiene a las 12:30", not estacion.en_horario(12.5))
	_comprobar("la herreria vuelve a las 14:00", estacion.en_horario(14.0))
	_comprobar("la herreria se detiene a las 19:00", not estacion.en_horario(19.0))

	var estacion_taberna := EstacionTrabajo.new()
	estacion_taberna.horario_id = "tabernero"
	estacion_taberna.actividades_productivas = ["trabajar", "taberna"]
	_comprobar("la taberna prepara a las 10:00", estacion_taberna.en_horario(10.0))
	_comprobar("la taberna sirve a las 20:00", estacion_taberna.en_horario(20.0))
	_comprobar("la taberna descansa a las 14:00", not estacion_taberna.en_horario(14.0))
	_comprobar("existen reglas data-driven de necesidades",
		BaseDeDatos.necesidad("hambre") != null
		and BaseDeDatos.necesidad("energia") != null
		and BaseDeDatos.necesidad("moral") != null)

	pirata = Pirata.new()
	add_child(pirata)
	pirata.montar("prueba", "Pirata de Prueba", Vector2i(4, 4), Vector2i(6, 6), 7)
	_comprobar("el pirata reutiliza el actor base", pirata is Actor)
	_comprobar("el pirata conserva su posición en pos_tile",
		pirata.pos == pirata.pos_tile)
	_comprobar("el montaje antiguo conserva trabajo igual a casa",
		pirata.trabajo == pirata.casa)
	pirata.montar("prueba_rutina", "Pirata Rutina", Vector2i(2, 2), Vector2i(6, 6),
		11, "herrero", Vector2i(8, 8))
	_comprobar("la rutina acepta un destino de trabajo separado",
		pirata.casa == Vector2i(2, 2) and pirata.trabajo == Vector2i(8, 8))
	_comprobar("el pirata tiene identidad estable", pirata.identidad != null)
	_comprobar("el NPC expone un inventario base propio",
		pirata.inventario() != null and pirata.inventario() is Inventario)
	pirata.inventario().anadir("raciones", 1)
	pirata.hambre = 40.0
	var comida_personal := pirata.consumir_item_personal("raciones")
	_comprobar("el NPC consume comida desde su inventario",
		comida_personal.get("ok", false) and pirata.hambre > 40.0
		and pirata.inventario().cantidad("raciones") == 0)
	pirata.inventario().anadir("ron", 1)
	pirata.moral_personal = 40.0
	var ron_personal := pirata.consumir_item_personal("ron")
	_comprobar("el NPC consume ron desde su inventario",
		ron_personal.get("ok", false) and pirata.moral_personal > 40.0
		and pirata.inventario().cantidad("ron") == 0)
	pirata.inventario().anadir("raciones", 1)
	pirata.hambre = 45.0
	pirata.tarea = Pirata.Tarea.COMIENDO
	var consumo_rutina := pirata.atender_necesidad_de_rutina()
	_comprobar("la rutina elige comida disponible por datos",
		consumo_rutina.get("ok", false) and pirata.hambre > 45.0)
	pirata.tarea = Pirata.Tarea.TRABAJANDO
	var energia_antes := pirata.energia_personal
	pirata.actualizar_necesidades(1.0)
	_comprobar("el trabajo desgasta energia desde datos",
		pirata.energia_personal < energia_antes)
	pirata.tarea = Pirata.Tarea.DURMIENDO
	var energia_despues_trabajo := pirata.energia_personal
	pirata.actualizar_necesidades(1.0)
	_comprobar("dormir recupera energia desde datos",
		pirata.energia_personal > energia_despues_trabajo)
	pirata.inventario().anadir("ron", 2)
	pirata.oro_personal = 37
	pirata.hambre = 61.0
	pirata.energia_personal = 44.0
	pirata.moral_personal = 78.0
	NpcsMundo.anotar(pirata)
	var estado_npc: Dictionary = pirata.serializar()
	var pos_guardada := pirata.pos_tile
	pirata.colocar(Vector2(1.5, 1.5))
	pirata.aplicar_estado(estado_npc)
	_comprobar("el estado plano restaura la posición del pirata",
		pirata.pos_tile.is_equal_approx(pos_guardada))
	var registro_npcs: Dictionary = NpcsMundo._serializar()
	_comprobar("NpcsMundo registra estados sin nodos",
		registro_npcs.get("estados", {}).has(pirata.identidad.instancia))
	pirata.colocar(Vector2(1.5, 1.5))
	NpcsMundo._cargar(registro_npcs)
	_comprobar("NpcsMundo aplica estados a los NPC vivos",
		pirata.pos_tile.is_equal_approx(pos_guardada))
	_comprobar("NpcsMundo restaura el inventario personal",
		pirata.inventario().cantidad("ron") == 2)
	_comprobar("NpcsMundo restaura el oro personal",
		pirata.oro_personal == 37)
	_comprobar("NpcsMundo restaura necesidades personales",
		is_equal_approx(pirata.hambre, 61.0)
		and is_equal_approx(pirata.energia_personal, 44.0)
		and is_equal_approx(pirata.moral_personal, 78.0))
	var rejilla := TransitableRejilla.new(10, 10)
	rejilla.bloquear(Vector2i(5, 4), "muro de prueba")
	pirata.transitable = rejilla
	pirata.colocar(Vector2(4.5, 4.5))
	pirata.mover(Vector2.RIGHT, 0.5)
	_comprobar("la tripulación consulta la transitabilidad común",
		pirata.pos_tile.x <= 4.5)
	Reloj.hora = 21.0
	pirata._pensar(0.1)
	_comprobar("el pirata aplica el tramo de taberna", pirata.tarea == Pirata.Tarea.A_LA_TABERNA)
	pirata.queue_free()
	estacion.free()
	estacion_taberna.free()

	print("\n=== %d/%d correctas ===" % [pruebas - fallos, pruebas])
	get_tree().quit(1 if fallos > 0 else 0)

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	pruebas += 1
	if condicion:
		print("  OK    %s" % nombre)
	else:
		fallos += 1
		print("  FALLO %s   %s" % [nombre, detalle])
