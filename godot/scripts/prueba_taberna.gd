extends Node
## Prueba funcional de servicios de la taberna.

var fallos := 0
var pruebas := 0
var interior: InteriorEscena

func _ready() -> void:
	print("\n=== PRUEBAS DE TABERNA ===\n")
	Bolsa.mochila.vaciar()
	Bolsa.oro = 100
	Bolsa.energia = 10.0
	Motin.nivel = 50.0
	Motin.tripulacion = 8
	TabernaManager.marineros_contratados = 0
	Reloj.hora = 20.0
	TabernaManager.abrir()
	_p1_puesto()
	_p2_ronda()
	_p3_rumor()
	_p4_fallo_sin_insumos()
	_p5_reclutamiento()
	TabernaManager.cerrar()
	if is_instance_valid(interior):
		interior.queue_free()
	print("\n=== %d/%d correctas ===" % [pruebas - fallos, pruebas])
	get_tree().quit(1 if fallos > 0 else 0)

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	pruebas += 1
	if condicion:
		print("  OK    %s" % nombre)
	else:
		fallos += 1
		print("  FALLO %s   %s" % [nombre, detalle])

func _p1_puesto() -> void:
	var def := BaseDeDatos.interior("interior_taberna_pb")
	_comprobar("existe interior de taberna", def != null)
	if def == null:
		return
	interior = InteriorEscena.new()
	add_child(interior)
	interior.construir(def, Vector2i.ZERO, "taberna", "edificio_taberna_test")
	var puesto: Node = interior.actores.get_node_or_null("Mueble_puesto_taberna_4_2")
	_comprobar("el puesto está montado", puesto != null)
	_comprobar("el puesto es interactivo", puesto != null and puesto.is_in_group(Interactuable.GRUPO))
	if puesto != null:
		puesto.interactuar(null)
	_comprobar("el puesto abre la taberna", TabernaManager.abierta)

func _p2_ronda() -> void:
	Bolsa.mochila.anadir("raciones", 1)
	Bolsa.mochila.anadir("ron", 1)
	var energia_antes := Bolsa.energia
	var motin_antes := Motin.nivel
	var ok := TabernaManager.servir_ronda()
	_comprobar("sirve una ronda", ok)
	_comprobar("consume ración y ron", Bolsa.mochila.cantidad("raciones") == 0 and Bolsa.mochila.cantidad("ron") == 0)
	_comprobar("recupera energía", Bolsa.energia > energia_antes)
	_comprobar("mejora moral", Motin.nivel < motin_antes)

func _p3_rumor() -> void:
	var rumor := TabernaManager.escuchar_rumor()
	_comprobar("escucha un rumor", rumor != "")
	var npc := Pirata.new()
	add_child(npc)
	npc.montar("npc_prueba_taberna", "Marinero de Prueba", Vector2i(3, 3), Vector2i(4, 4), 77)
	npc.inventario().anadir("raciones", 1)
	npc.inventario().anadir("ron", 1)
	npc.hambre = 30.0
	npc.moral_personal = 30.0
	var servicio := TabernaManager.servir_ronda_a(npc)
	_comprobar("la taberna atiende a un NPC", servicio.get("ok", false))
	_comprobar("la ronda NPC usa su inventario personal",
		npc.inventario().esta_vacio())
	_comprobar("la ronda NPC recupera sus necesidades",
		npc.hambre > 30.0 and npc.moral_personal > 30.0)
	npc.queue_free()

func _p4_fallo_sin_insumos() -> void:
	var ok := TabernaManager.servir_ronda()
	_comprobar("rechaza ronda sin insumos", not ok)

func _p5_reclutamiento() -> void:
	var oro_antes := Bolsa.oro
	var tripulacion_antes := Motin.tripulacion
	var ok := TabernaManager.contratar_marinero()
	_comprobar("contrata un marinero", ok)
	_comprobar("cobra el coste", Bolsa.oro == oro_antes - TabernaManager.COSTE_MARINERO)
	_comprobar("aumenta la tripulación", Motin.tripulacion == tripulacion_antes + 1)
	_comprobar("registra el marinero", TabernaManager.marineros_contratados == 1)

	Bolsa.oro = 0
	ok = TabernaManager.contratar_marinero()
	_comprobar("rechaza contratación sin oro", not ok)
