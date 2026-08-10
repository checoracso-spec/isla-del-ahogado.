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

	pirata = Pirata.new()
	add_child(pirata)
	pirata.montar("prueba", "Pirata de Prueba", Vector2i(4, 4), Vector2i(6, 6), 7)
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
