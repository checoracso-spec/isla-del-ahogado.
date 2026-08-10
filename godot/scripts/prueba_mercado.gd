extends Node
## Prueba del vertical slice del Mercado de Portobello.

const RANURA_PRUEBA := 89
var fallos := 0
var pruebas := 0
var interior: InteriorEscena

func _ready() -> void:
	print("\n=== PRUEBAS DE MERCADO ===\n")
	Bolsa.mochila.vaciar()
	Bolsa.oro = 1000
	MercadoManager.stock.vaciar()
	MercadoManager._inicializado = false
	MercadoManager._inicializar_stock()
	MercadoManager.reiniciar_demanda()
	MercadoManager.abrir()

	_p1_puesto()
	_p2_comprar()
	_p3_vender()
	_p3b_oferta_dinamica()
	_p4_rechazar_sin_oro()
	_p5_guardar_stock()

	MercadoManager.cerrar()
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

func _p1_puesto() -> void:
	var def := BaseDeDatos.interior("interior_mercado_pb")
	_comprobar("existe interior de mercado", def != null)
	if def == null:
		return
	interior = InteriorEscena.new()
	add_child(interior)
	interior.construir(def, Vector2i.ZERO, "mercado", "edificio_mercado_test")
	var puesto: Node = interior.actores.get_node_or_null("Mueble_puesto_mercado_4_2")
	_comprobar("el puesto está montado", puesto != null)
	_comprobar("el puesto es interactivo", puesto != null and puesto.is_in_group(Interactuable.GRUPO))
	if puesto != null:
		puesto.interactuar(null)
	_comprobar("el puesto abre el mercado", MercadoManager.abierto)

func _p2_comprar() -> void:
	var antes := Bolsa.oro
	var stock_antes := MercadoManager.stock.cantidad("ron")
	var precio_antes := MercadoManager.precio_compra("ron")
	var ok := MercadoManager.comprar("ron", 1)
	_comprobar("compra ron", ok)
	_comprobar("descuenta doblones", Bolsa.oro == antes - precio_antes)
	_comprobar("ron llega a mochila", Bolsa.mochila.cantidad("ron") == 1)
	_comprobar("reduce stock", MercadoManager.stock.cantidad("ron") == stock_antes - 1)

func _p3_vender() -> void:
	var antes := Bolsa.oro
	var ok := MercadoManager.vender("ron", 1)
	_comprobar("vende ron", ok)
	_comprobar("ron sale de mochila", Bolsa.mochila.cantidad("ron") == 0)
	_comprobar("ingresa doblones", Bolsa.oro == antes + MercadoManager.precio_venta("ron"))

func _p3b_oferta_dinamica() -> void:
	var precio_normal := MercadoManager.precio_compra("ron")
	MercadoManager.stock.retirar("ron", 10)
	_comprobar("la oferta baja cuando el stock escasea",
		MercadoManager.indice_oferta("ron") < 0.25)
	_comprobar("la escasez eleva el precio de compra",
		MercadoManager.precio_compra("ron") > precio_normal)
	MercadoManager.stock.anadir("ron", 10)
	var demanda_normal := MercadoManager.precio_compra("ron")
	MercadoManager.registrar_demanda("ron", 0.4)
	_comprobar("la demanda queda registrada", MercadoManager.indice_demanda("ron") > 1.0)
	_comprobar("la demanda eleva el precio", MercadoManager.precio_compra("ron") > demanda_normal)
	var demanda_alta := MercadoManager.indice_demanda("ron")
	MercadoManager._reajustar_demanda(2)
	_comprobar("la demanda se normaliza gradualmente al amanecer",
		MercadoManager.indice_demanda("ron") < demanda_alta
		and MercadoManager.indice_demanda("ron") > 1.0)
	MercadoManager.reiniciar_demanda()

func _p4_rechazar_sin_oro() -> void:
	Bolsa.oro = 0
	var ok := MercadoManager.comprar("acero_imperial", 1)
	_comprobar("rechaza compra sin oro", not ok)
	_comprobar("no entrega acero", Bolsa.mochila.cantidad("acero_imperial") == 0)

func _p5_guardar_stock() -> void:
	Bolsa.oro = 1000
	var guardo := Guardado.guardar(RANURA_PRUEBA)
	var ron_esperado := MercadoManager.stock.cantidad("ron")
	MercadoManager.stock.vaciar()
	var cargo := Guardado.cargar(RANURA_PRUEBA)
	_comprobar("guarda y carga stock", guardo and cargo)
	_comprobar("stock sobrevive", MercadoManager.stock.cantidad("ron") == ron_esperado)
	_comprobar("demanda sobrevive", is_equal_approx(MercadoManager.indice_demanda("ron"), 1.0))
