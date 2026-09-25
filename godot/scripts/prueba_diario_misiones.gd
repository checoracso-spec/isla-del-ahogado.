extends Node
## Prueba enfocada del diario de misiones MAREA-017.

const MISION := "marea_009_naufragio"

var correctas := 0
var fallos := 0
var mundo: Mundo

func _ready() -> void:
	Misiones.reiniciar()
	Bolsa.mochila.vaciar()
	var escena: PackedScene = load("res://escenas/mundo.tscn")
	mundo = escena.instantiate() as Mundo
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	Reloj.pausado = true
	await _ejecutar()
	print("=== %d/%d comprobaciones de MAREA-017 ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	var panel: PanelDiarioMisiones = mundo.panel_diario_misiones
	_comprobar("el diario arranca oculto", not panel.abierto())
	_comprobar("J queda registrado para el diario", InputMap.has_action("diario_misiones")
		and InputMap.action_get_events("diario_misiones").any(
			func(e): return e is InputEventKey and e.physical_keycode == KEY_J))
	_comprobar("las dos misiones están en el diario", Misiones.ids().size() == 2)

	var evento := InputEventKey.new()
	evento.physical_keycode = KEY_J
	evento.pressed = true
	Input.parse_input_event(evento)
	await get_tree().process_frame
	_comprobar("J abre el diario", panel.abierto())
	var resumen: Label = panel.find_child("ResumenMisiones", true, false)
	_comprobar("muestra nombre, encargante y estado", resumen.text.contains("Restos del Naufragio")
		and resumen.text.contains("Calico") and resumen.text.contains("Disponible"))
	_comprobar("el progreso inicial es cero de dos", resumen.text.contains("Madera de Naufragio: 0/2"))

	Misiones.aceptar(MISION)
	Bolsa.mochila.anadir("madera_naufragio", 4)
	_comprobar("el refresco por objetivo refleja el estado completado",
		resumen.text.contains("Objetivo completado"))
	_comprobar("el progreso se limita a la cantidad requerida",
		resumen.text.contains("Madera de Naufragio: 2/2")
		and not resumen.text.contains("Madera de Naufragio: 4/2"))
	Misiones.entregar(MISION)
	_comprobar("el refresco por señal muestra la misión entregada",
		resumen.text.contains("Estado: Entregada"))

	var soltar_j := InputEventKey.new()
	soltar_j.physical_keycode = KEY_J
	Input.parse_input_event(soltar_j)
	await get_tree().process_frame
	var j_cerrar := InputEventKey.new()
	j_cerrar.physical_keycode = KEY_J
	j_cerrar.pressed = true
	Input.parse_input_event(j_cerrar)
	await get_tree().process_frame
	_comprobar("J también cierra el diario", not panel.abierto())
	var soltar_j_cerrar := InputEventKey.new()
	soltar_j_cerrar.physical_keycode = KEY_J
	Input.parse_input_event(soltar_j_cerrar)
	await get_tree().process_frame
	panel.abrir()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await get_tree().process_frame
	_comprobar("Esc cierra el diario y la prueba continúa", not panel.abierto())
	var soltar_escape := InputEventKey.new()
	soltar_escape.keycode = KEY_ESCAPE
	Input.parse_input_event(soltar_escape)
	await get_tree().process_frame

	panel.abrir()
	Interiores.salio.emit("test_diario_misiones")
	_comprobar("salir de un interior cierra el diario", not panel.abierto())
	var codigo_panel := FileAccess.get_file_as_string("res://scripts/ui/panel_diario_misiones.gd")
	var mutadores := ["Misiones.registrar(", "Misiones.aceptar(",
		"Misiones.completar_objetivo(", "Misiones.entregar(", "Misiones.reiniciar(",
		"Bolsa.mochila.anadir(", "Bolsa.mochila.retirar(", "Bolsa.consumir(",
		"Bolsa.ingresar(", "Guardado."]
	var solo_lectura := true
	for mutador in mutadores:
		if codigo_panel.contains(mutador):
			solo_lectura = false
	_comprobar("el panel sólo consume APIs de lectura", solo_lectura)

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
