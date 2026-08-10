extends Node

const MundoScript := preload("res://scripts/mundo.gd")
const Datos := preload("res://scripts/prueba_persistencia_npc_datos.gd")
const RANURA := Datos.RANURA

func _ready() -> void:
	Reloj.pausado = true
	var mundo: Mundo = MundoScript.new()
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	var npc: Pirata = _barbanegra(mundo)
	if npc == null:
		printerr("A-npc: no se encontro Barbanegra")
		get_tree().quit(1)
		return
	var posicion := Vector2(npc.casa) + Vector2(0.5, 0.5)
	if not mundo.transitable.cabe_en(posicion, npc.huella):
		printerr("A-npc: la posicion de prueba no es transitable")
		get_tree().quit(1)
		return
	npc.colocar(posicion)
	npc.destino = posicion
	npc.direccion = Vector2.RIGHT
	npc.tarea = Pirata.Tarea.DURMIENDO
	npc.estado = "idle"
	npc.inventario().vaciar()
	npc.oro_personal = 0
	npc.inventario().anadir("ron", Datos.RON)
	npc.oro_personal = Datos.ORO
	npc.hambre = Datos.HAMBRE
	npc.energia_personal = Datos.ENERGIA
	npc.moral_personal = Datos.MORAL
	NpcsMundo.anotar(npc)
	if not Guardado.guardar(RANURA):
		printerr("A-npc: no pudo guardar")
		get_tree().quit(1)
		return
	print("A-npc: guardado %s en %s" % [npc.identidad.instancia, Guardado.ruta(RANURA)])
	get_tree().quit(0)

func _barbanegra(mundo: Mundo) -> Pirata:
	for npc in mundo.piratas:
		if npc.id_personaje == "barbanegra":
			return npc
	return null
