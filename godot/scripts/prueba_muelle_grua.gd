extends Node

var correctas := 0
var fallos := 0
var mundo: Mundo

func _ready() -> void:
	var escena: PackedScene = load("res://escenas/mundo.tscn")
	mundo = escena.instantiate() as Mundo
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	Reloj.pausado = true
	_ejecutar()
	print("=== %d/%d comprobaciones de grúa del muelle ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	MuelleManager.reiniciar()
	MuelleManager.montar(mundo.fuentes_recurso)
	Almacen.vaciar()
	Almacen.anadir("tablon_tratado", MuelleManager.COSTE_TABLONES)
	Almacen.anadir("doblon", MuelleManager.COSTE_DOBLONES)

	var panel: PanelMuelle = mundo.panel_muelle
	panel.abrir("abierta")
	var boton: Button = panel.find_child("ActivarGrua", true, false) as Button
	_comprobar("el panel ofrece instalar la red", boton != null and not boton.disabled)
	if boton == null:
		return
	boton.pressed.emit()
	_comprobar("la red queda activa", MuelleManager.grua_activa)
	_comprobar("se descuentan los materiales de instalación",
		Almacen.cantidad("tablon_tratado") == 0 and Almacen.cantidad("doblon") == 0)
	_comprobar("se detiene la receta automática antigua",
		_notas_rastrillo_activo())

	var lote := MuelleManager.ejecutar_recoleccion_ahora()
	_comprobar("la red recoge desde el naufragio", int(lote.get("ciclos", 0)) == 1)
	_comprobar("la red entrega la carga al almacén",
		Almacen.cantidad("madera_naufragio") == 2
		and Almacen.cantidad("polvora_humeda") == 1)
	_comprobar("Guardado registra el estado del muelle",
		Guardado.secciones_activas().has("muelle"))

	var serial: Dictionary = MuelleManager._serializar()
	MuelleManager.reiniciar()
	MuelleManager._cargar(serial)
	_comprobar("la red activa se recupera desde datos planos",
		MuelleManager.grua_activa and MuelleManager.fuente_instancia != "")

func _notas_rastrillo_activo() -> bool:
	for estacion in mundo.estaciones:
		if estacion.edificio_id == "muelle_grua" and estacion.receta_id == "rastrillar_marea":
			return not estacion.activa
	return false

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
