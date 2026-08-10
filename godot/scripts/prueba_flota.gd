extends Node

var correctas := 0
var fallos := 0

func _ready() -> void:
	await get_tree().process_frame
	_ejecutar()
	print("=== %d/%d comprobaciones de flota ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	FlotaMundo.reiniciar()
	_comprobar("hay barcos definidos en BaseDeDatos", BaseDeDatos.barcos.size() >= 3)
	_comprobar("la flota crea tres instancias estables", FlotaMundo.ids().size() == 3)
	_comprobar("la balandra está disponible en la isla",
		FlotaMundo.disponible_para("balandra", "isla_principal") == "balandra_001")
	var estado := FlotaMundo.estado("balandra_001")
	_comprobar("la instancia conserva definition_id", estado.get("definition_id", "") == "balandra")
	_comprobar("la instancia tiene salud inicial", int(estado.get("salud", 0)) > 0)
	_comprobar("la instancia tiene posición persistente",
		estado.get("posicion", "") == "isla_principal")
	_comprobar("la bodega usa el Inventario base",
		FlotaMundo.inventario_de("balandra_001") is Inventario)
	_comprobar("la bodega respeta capacidad de volumen",
		FlotaMundo.inventario_de("balandra_001").capacidad == 60.0)
	_comprobar("carga mercancía en la bodega",
		FlotaMundo.cargar_mercancia("balandra_001", "ron", 2) == 2)
	_comprobar("la bodega conserva la carga viva",
		FlotaMundo.inventario_de("balandra_001").cantidad("ron") == 2)
	_comprobar("despacha la nave seleccionada",
		FlotaMundo.despachar("balandra_001", "isla_principal", "isla_ceniza"))
	_comprobar("la nave pasa al estado mar", FlotaMundo.estado("balandra_001").get("estado", "") == "mar")
	_comprobar("una nave en mar ya no está disponible",
		FlotaMundo.disponible_para("balandra", "isla_principal") == "")
	_comprobar("la nave conserva destino", FlotaMundo.estado("balandra_001").get("destino", "") == "isla_ceniza")
	_comprobar("la llegada atraca la nave", FlotaMundo.llegar("balandra_001", "isla_ceniza"))
	_comprobar("la nave queda disponible en el destino",
		FlotaMundo.disponible_para("balandra", "isla_ceniza") == "balandra_001")
	var plano := FlotaMundo._serializar()
	_comprobar("serializa la flota sin nodos", plano.get("barcos", {}) is Dictionary)
	FlotaMundo.reiniciar()
	FlotaMundo._cargar(plano)
	_comprobar("restaura el puerto de la nave", FlotaMundo.estado("balandra_001").get("posicion", "") == "isla_ceniza")
	_comprobar("restaura la carga de la bodega", FlotaMundo.inventario_de("balandra_001").cantidad("ron") == 2)
	FlotaMundo.aplicar_dano("balandra_001", 20)
	_comprobar("repara sin superar salud máxima", FlotaMundo.reparar("balandra_001", 999) == 20
		and FlotaMundo.estado("balandra_001").get("salud", 0) == BaseDeDatos.barco("balandra").salud_max)

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
