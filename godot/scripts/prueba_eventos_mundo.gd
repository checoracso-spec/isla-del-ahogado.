extends Node

var correctas := 0
var fallos := 0

func _ready() -> void:
	print("\n=== PRUEBAS DE EVENTOS DEL MUNDO ===\n")
	EventosMundo.reiniciar()
	_comprobar("la base de datos declara eventos", BaseDeDatos.eventos.size() == 3)
	_comprobar("el bloqueo tiene definición tipada",
		BaseDeDatos.evento("bloqueo_corona") != null)
	_comprobar("la marea declara capacidad extra de naufragios",
		BaseDeDatos.evento("marea_de_naufragios") != null
		and BaseDeDatos.evento("marea_de_naufragios").multiplicadores_recursos.get(
			"restos_naufragio", 1.0) > 1.0)
	_comprobar("el mundo empieza sin eventos activos", EventosMundo.activos().is_empty())

	var precio_normal := MercadoManager.precio_compra("acero_imperial")
	var riesgo_normal := EventosMundo.riesgo_viaje(0.20)
	_comprobar("inicia un evento data-driven",
		EventosMundo.iniciar("bloqueo_corona"))
	_comprobar("el evento queda activo", EventosMundo.activo("bloqueo_corona"))
	_comprobar("el evento modifica el precio de acero",
		MercadoManager.precio_compra("acero_imperial") > precio_normal)
	_comprobar("el evento modifica el riesgo de viaje",
		EventosMundo.riesgo_viaje(0.20) > riesgo_normal)
	_comprobar("el mapa global consulta el riesgo del evento",
		MapaGlobal.riesgo_ruta("principal_ceniza") > BaseDeDatos.ruta("principal_ceniza").riesgo)
	_comprobar("el riesgo queda limitado al cien por ciento",
		EventosMundo.riesgo_viaje(0.90) <= 1.0)
	_comprobar("no permite duplicar un evento activo",
		not EventosMundo.iniciar("bloqueo_corona"))

	const RANURA_PRUEBA := 91
	Guardado.borrar(RANURA_PRUEBA)
	var guardo := Guardado.guardar(RANURA_PRUEBA)
	EventosMundo.reiniciar()
	var cargo := Guardado.cargar(RANURA_PRUEBA)
	_comprobar("guarda y carga el evento en una partida", guardo and cargo)
	_comprobar("la partida restaura el bloqueo activo",
		EventosMundo.activo("bloqueo_corona"))
	Guardado.borrar(RANURA_PRUEBA)

	var serial := EventosMundo._serializar()
	EventosMundo.reiniciar()
	EventosMundo._cargar(serial)
	_comprobar("los eventos activos se restauran desde datos planos",
		EventosMundo.activo("bloqueo_corona"))
	_comprobar("el estado restaurado conserva su vencimiento",
		EventosMundo.estado("bloqueo_corona").has("termina"))
	_comprobar("termina un evento manualmente", EventosMundo.terminar("bloqueo_corona"))
	_comprobar("el precio vuelve al valor base al terminar",
		MercadoManager.precio_compra("acero_imperial") == precio_normal)
	_comprobar("terminar un evento inexistente es seguro",
		not EventosMundo.terminar("evento_inexistente"))

	print("=== %d/%d comprobaciones de eventos del mundo ===" % [correctas, correctas + fallos])
	get_tree().quit(1 if fallos > 0 else 0)

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
