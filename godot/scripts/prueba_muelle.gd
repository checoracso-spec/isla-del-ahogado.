extends Node
## Prueba del puesto de gestion del muelle.

const PuestoMuelleScript := preload("res://scripts/interiores/puesto_muelle.gd")
const PanelMuelleScript := preload("res://scripts/ui/panel_muelle.gd")

var fallos := 0
var pruebas := 0

func _ready() -> void:
	print("\n=== PRUEBAS DE MUELLE ===\n")
	Reloj.pausado = true
	var puesto: Node = PuestoMuelleScript.new()
	add_child(puesto)

	Reloj.hora = 10.0
	_comprobar("el muelle esta operativo durante la jornada", puesto.estado_operativo() == "abierta")
	_comprobar("el muelle muestra Gestionar Carga de dia", puesto.texto_accion() == "Gestionar Carga")

	var estados: Array[String] = []
	puesto.gestionar.connect(func(estado: String): estados.append(estado))
	puesto.interactuar(self)
	_comprobar("la puerta de gestion emite el estado abierto", estados.size() == 1 and estados[0] == "abierta")

	Reloj.hora = 20.0
	_comprobar("el muelle se detiene fuera de horario", puesto.estado_operativo() == "detenida")
	_comprobar("el muelle muestra Detenido por la noche", puesto.texto_accion() == "Detenido por la noche")
	puesto.interactuar(self)
	_comprobar("la puerta de gestion emite el estado detenido", estados.size() == 2 and estados[1] == "detenida")

	var panel = PanelMuelleScript.new()
	add_child(panel)
	panel.abrir("detenida")
	var boton: Button = panel.find_child("DescargarPuerto", true, false) as Button
	_comprobar("la descarga queda bloqueada de noche", boton.disabled)
	panel.abrir("abierta")
	_comprobar("la descarga se habilita de dia", not boton.disabled)
	var selector: OptionButton = panel.find_child("SelectorRuta", true, false) as OptionButton
	_comprobar("el muelle ofrece dos rutas", selector.item_count == 2)
	var info_ruta: Label = panel.find_child("InfoRuta", true, false) as Label
	_comprobar("la ruta muestra capacidad y requisitos",
		info_ruta.text.contains("Capacidad") and info_ruta.text.contains("Seda Robada"))
	var zarpar: Button = panel.find_child("EnviarExpedicion", true, false) as Button
	_comprobar("la expedicion se habilita de dia", not zarpar.disabled)
	Almacen.anadir("seda_robada", 2)
	Almacen.anadir("tablon_tratado", 2)
	Almacen.anadir("canon", 2)
	zarpar.pressed.emit()
	var en_mar := RastreoCarga.en_mar()
	_comprobar("la ruta crea un cargamento en el mar", en_mar.size() == 1)
	if en_mar.size() == 1:
		var id: String = en_mar[0]["id"]
		RastreoCarga.manifiestos[id]["riesgo"] = 0.0
		for dia in range(5):
			if RastreoCarga.manifiestos.has(id):
				RastreoCarga._pasar_dia(dia)
		var estado_final := int(RastreoCarga.manifiestos.get(id, {}).get("estado", -1))
		_comprobar("la carga llega al puerto", estado_final == RastreoCarga.Ubicacion.EN_PUERTO)
		_comprobar("la carga queda atracada", RastreoCarga.en_puerto().size() == 1)
		_comprobar("descargar devuelve la mercancia a los cofres",
			RastreoCarga.descargar(id) and Almacen.cantidad("seda_robada") == 2)
	var interceptado := {
		"id": "exp_interceptada",
		"barco": "balandra",
		"contenido": { "seda_robada": 2 },
		"canones": 0,
		"estado": RastreoCarga.Ubicacion.EN_MAR,
		"interceptado": true,
		"riesgo": 0.2,
	}
	RastreoCarga.manifiestos[interceptado["id"]] = interceptado
	RastreoCarga.informe_interceptacion.emit(interceptado)
	var soltar: Button = panel.find_child("SoltarLastre", true, false) as Button
	var luchar: Button = panel.find_child("LucharInterceptacion", true, false) as Button
	_comprobar("muestra decision de interceptacion", soltar.visible and luchar.visible)
	soltar.pressed.emit()
	_comprobar("soltar lastre resuelve la interceptacion",
		RastreoCarga.manifiestos.has("exp_interceptada") and not RastreoCarga.manifiestos["exp_interceptada"]["interceptado"])
	_comprobar("oculta las decisiones despues de resolver", not soltar.visible and not luchar.visible)
	RastreoCarga.manifiestos["exp_guardada"] = {
		"id": "exp_guardada",
		"barco": "balandra",
		"contenido": { "madera_naufragio": 2 },
		"canones": 0,
		"estado": RastreoCarga.Ubicacion.EN_MAR,
		"dias_restantes": 2,
	}
	_comprobar("Guardado registra las expediciones", Guardado.secciones_activas().has("rastreo_carga"))
	var snapshot: Dictionary = RastreoCarga._serializar()
	RastreoCarga.manifiestos.clear()
	RastreoCarga._cargar(snapshot)
	_comprobar("carga recupera las expediciones", RastreoCarga.manifiestos.has("exp_guardada"))

	print("\n=== %d/%d correctas ===" % [pruebas - fallos, pruebas])
	get_tree().quit(1 if fallos > 0 else 0)

func _comprobar(nombre: String, condicion: bool) -> void:
	pruebas += 1
	if condicion:
		print("  OK    %s" % nombre)
	else:
		fallos += 1
		print("  FALLO %s" % nombre)
