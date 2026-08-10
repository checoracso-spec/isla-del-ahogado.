extends Node
## Prueba funcional de la primera estación manual: la fragua de la herrería.
## No usa Almacen: valida mochila, recetas, sustitutos, interacción y guardado.

const RANURA_PRUEBA := 88
var fallos := 0
var pruebas := 0
var interior: InteriorEscena

func _ready() -> void:
	print("\n=== PRUEBAS DE CRAFTEO MANUAL ===\n")
	Reloj.pausado = true
	CraftingManager.cancelar()
	CraftingManager.cerrar()
	Bolsa.mochila.vaciar()
	Bolsa.energia = Bolsa.energia_max
	
	_p1_estacion()
	_p2_fabricacion_normal()
	_p3_fallo_sin_consumo()
	_p4_sustitucion()
	_p5_guardado_trabajo()
	_p6_abastecer_desde_almacen()
	_p7_acciones_de_objetos()

	if is_instance_valid(interior):
		interior.queue_free()
	Guardado.borrar(RANURA_PRUEBA)
	print("\n=== %d/%d correctas ===" % [pruebas - fallos, pruebas])
	get_tree().quit(1 if fallos > 0 else 0)

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	pruebas += 1
	if condicion:
		print("  OK    %s" % nombre)
	else:
		fallos += 1
		print("  FALLO %s   %s" % [nombre, detalle])

func _reiniciar_mochila() -> void:
	CraftingManager.cancelar()
	Bolsa.mochila.vaciar()
	Bolsa.energia = Bolsa.energia_max
	CraftingManager.abrir("herreria")

func _terminar_trabajo() -> void:
	var antes := Reloj.pausado
	Reloj.pausado = false
	CraftingManager._process(100.0)
	Reloj.pausado = antes

func _p1_estacion() -> void:
	print("1. La fragua existe como estación interactiva")
	var def := BaseDeDatos.interior("interior_herreria_pb")
	_comprobar("existe el interior de herrería", def != null)
	if def == null:
		return
	interior = InteriorEscena.new()
	add_child(interior)
	interior.construir(def, Vector2i.ZERO, "herreria", "edificio_test_0001")
	var fragua: Node = interior.actores.get_node_or_null("Mueble_fragua_1_1")
	_comprobar("la fragua está montada", fragua != null)
	_comprobar("la fragua es interactiva", fragua != null and fragua.is_in_group(Interactuable.GRUPO))
	if fragua != null:
		fragua.interactuar(null)
	_comprobar("la interacción abre herrería", CraftingManager.estacion_id_actual == "herreria")
	var banco: Node = interior.actores.get_node_or_null("Mueble_banco_trabajo_6_1")
	_comprobar("el banco de trabajo está montado", banco != null)
	_comprobar("el banco también es interactivo", banco != null and banco.is_in_group(Interactuable.GRUPO))
	if banco != null:
		_comprobar("el banco tiene acción propia", banco.texto_accion() == "Usar banco de trabajo")
		banco.interactuar(null)
	_comprobar("el banco abre la misma herrería", CraftingManager.estacion_id_actual == "herreria")

func _p2_fabricacion_normal() -> void:
	print("2. Fabricación normal")
	_reiniciar_mochila()
	Bolsa.mochila.anadir("acero_imperial", 1)
	Bolsa.mochila.anadir("carbon", 2)
	var energia_antes := Bolsa.energia
	var inicio := CraftingManager.fabricar("forjar_herramienta")
	_comprobar("inicia con materiales", inicio)
	_comprobar("consume acero", Bolsa.mochila.cantidad("acero_imperial") == 0)
	_comprobar("consume carbón", Bolsa.mochila.cantidad("carbon") == 0)
	_comprobar("consume energía", Bolsa.energia < energia_antes)
	_comprobar("queda un trabajo activo", CraftingManager.trabajando())
	_terminar_trabajo()
	_comprobar("entrega herramientas", Bolsa.mochila.cantidad("herramienta") == 2)
	_comprobar("termina el trabajo", not CraftingManager.trabajando())

func _p3_fallo_sin_consumo() -> void:
	print("3. Falta de materiales sin consumo parcial")
	_reiniciar_mochila()
	Bolsa.mochila.anadir("acero_imperial", 1)
	var energia_antes := Bolsa.energia
	var inicio := CraftingManager.fabricar("forjar_herramienta")
	_comprobar("rechaza lote incompleto", not inicio)
	_comprobar("conserva el acero", Bolsa.mochila.cantidad("acero_imperial") == 1)
	_comprobar("no consume energía al fallar", is_equal_approx(Bolsa.energia, energia_antes))

func _p4_sustitucion() -> void:
	print("4. Sustitución de emergencia")
	_reiniciar_mochila()
	Bolsa.mochila.anadir("acero_imperial", 3)
	Bolsa.mochila.anadir("carbon", 4)
	Bolsa.mochila.anadir("grasa_ballena", 4)
	var inicio := CraftingManager.fabricar("forjar_canon")
	_comprobar("inicia usando grasa de ballena", inicio)
	_comprobar("calidad de contingencia 65%%",
		is_equal_approx(float(CraftingManager.trabajo.get("calidad", 0.0)), 0.65))
	_comprobar("consume grasa", Bolsa.mochila.cantidad("grasa_ballena") == 0)
	_terminar_trabajo()
	_comprobar("entrega cañón", Bolsa.mochila.cantidad("canon") == 1)

func _p5_guardado_trabajo() -> void:
	print("5. Guardado plano del trabajo activo")
	_reiniciar_mochila()
	Bolsa.mochila.anadir("acero_imperial", 1)
	Bolsa.mochila.anadir("carbon", 2)
	var inicio := CraftingManager.fabricar("forjar_herramienta")
	var guardo := Guardado.guardar(RANURA_PRUEBA)
	_comprobar("guarda una fabricación activa", inicio and guardo)
	CraftingManager.cancelar()
	Bolsa.mochila.vaciar()
	var cargo := Guardado.cargar(RANURA_PRUEBA)
	_comprobar("carga la fabricación activa", cargo and CraftingManager.trabajando())
	_comprobar("carga materiales guardados", Bolsa.mochila.cantidad("acero_imperial") == 0
		and Bolsa.mochila.cantidad("carbon") == 0)
	_terminar_trabajo()
	_comprobar("completa después de cargar", Bolsa.mochila.cantidad("herramienta") == 2)

func _p6_abastecer_desde_almacen() -> void:
	print("6. Abastecimiento explícito desde Almacen")
	CraftingManager.cancelar()
	Bolsa.mochila.vaciar()
	Almacen.vaciar()

func _p7_acciones_de_objetos() -> void:
	print("7. Consumir y equipar objetos")
	Bolsa.mochila.vaciar()
	Bolsa.energia = 10.0
	Motin.nivel = 50.0
	Bolsa.mochila.anadir("raciones", 1)
	Bolsa.mochila.anadir("ron", 1)
	Bolsa.mochila.anadir("herramienta", 1)
	var comida := Bolsa.consumir("raciones")
	_comprobar("consume raciones", comida.get("ok", false))
	_comprobar("raciones recuperan energía", Bolsa.energia == 40.0)
	_comprobar("raciones desaparecen", Bolsa.mochila.cantidad("raciones") == 0)
	var ron := Bolsa.consumir("ron")
	_comprobar("consume ron", ron.get("ok", false))
	_comprobar("el ron reduce motín", Motin.nivel < 50.0)
	var herramienta := Bolsa.equipar_desde_mochila("herramienta")
	_comprobar("equipa herramienta", herramienta.get("ok", false))
	_comprobar("herramienta queda equipada", Bolsa.tiene_herramienta("herramienta"))
	Almacen.anadir("grasa_ballena", 3)
	Almacen.anadir("azufre_volcanico", 2)
	CraftingManager.abrir("herreria")
	var resultado := CraftingManager.abastecer("destilar_alternativo")
	_comprobar("trasvasa materiales del almacén", resultado.get("ok", false))
	_comprobar("grasa llega a la mochila", Bolsa.mochila.cantidad("grasa_ballena") == 3)
	_comprobar("azufre llega a la mochila", Bolsa.mochila.cantidad("azufre_volcanico") == 2)
	Almacen.vaciar()
