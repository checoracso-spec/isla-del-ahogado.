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
	print("=== %d/%d comprobaciones de cultivos en mundo ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	_comprobar("el mundo crea tres parcelas", mundo.parcelas_cultivo.size() == 3)
	if mundo.parcelas_cultivo.size() < 3:
		return
	var por_tipo := {}
	for parcela in mundo.parcelas_cultivo:
		por_tipo[parcela.definicion_id] = parcela
	_comprobar("existe parcela de cítricos", por_tipo.has("citricos"))
	_comprobar("existe parcela de caña", por_tipo.has("cana_azucar"))
	_comprobar("existe parcela de tabaco", por_tipo.has("tabaco"))
	_comprobar("las parcelas ocupan casillas distintas", _casillas_distintas(por_tipo.values()))

	var parcela = por_tipo["citricos"]
	_comprobar("la parcela es transitable", mundo.transitable.puede_pisar(parcela.casilla()))
	_comprobar("la parcela empieza sin sembrar", CultivosMundo.etapa(parcela.identidad.instancia) == 0)
	_comprobar("la parcela ofrece sembrar cítricos", parcela.texto_accion() == "Sembrar Cítricos")

	Bolsa.mochila.vaciar()
	Bolsa.mochila.anadir("semilla_citrico", 1)
	parcela.interactuar(mundo.jugador)
	_comprobar("sembrar consume la semilla", Bolsa.mochila.cantidad("semilla_citrico") == 0)
	_comprobar("sembrar deja aviso en la bitácora", _bitacora_contiene(mundo, "Sembraste Cítricos"))
	_comprobar("el cultivo pasa a etapa inicial", CultivosMundo.etapa(parcela.identidad.instancia) == 1)

	var serial: Dictionary = CultivosMundo._serializar()
	CultivosMundo.reiniciar()
	CultivosMundo._cargar(serial)
	_comprobar("el cultivo sembrado se conserva al cargar", CultivosMundo.etapa(parcela.identidad.instancia) == 1)

	Reloj.dia = 2
	Reloj.hora = 1.6
	_comprobar("el cultivo madura según el reloj", CultivosMundo.etapa(parcela.identidad.instancia) == 3)
	_comprobar("la parcela ofrece cosechar", parcela.texto_accion() == "Cosechar Cítricos")
	parcela.interactuar(mundo.jugador)
	_comprobar("la cosecha llega a la mochila", Bolsa.mochila.cantidad("citricos") == 3)
	_comprobar("cosechar deja aviso en la bitácora", _bitacora_contiene(mundo, "Cosecha de Cítricos"))
	_comprobar("la parcela vuelve a estar disponible", CultivosMundo.etapa(parcela.identidad.instancia) == 0)

func _bitacora_contiene(mundo_real: Mundo, texto: String) -> bool:
	for linea in mundo_real._bitacora:
		if texto in str(linea):
			return true
	return false

func _casillas_distintas(parcelas: Array) -> bool:
	var vistas := {}
	for parcela in parcelas:
		var c: Vector2i = parcela.casilla()
		if vistas.has(c):
			return false
		vistas[c] = true
	return true

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
