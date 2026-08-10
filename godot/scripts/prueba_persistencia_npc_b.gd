extends Node

const MundoScript := preload("res://scripts/mundo.gd")
const RANURA := 96

var correctas := 0
var fallos := 0

func _ready() -> void:
	Reloj.pausado = true
	var mundo: Mundo = MundoScript.new()
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	var npc: Pirata = _barbanegra(mundo)
	_comprobar("el proceso B crea el NPC desde datos", npc != null)
	_comprobar("la partida A/B existe", Guardado.existe(RANURA))
	if npc != null and Guardado.existe(RANURA):
		_comprobar("carga el estado NPC", Guardado.cargar(RANURA))
		await get_tree().process_frame
		var esperado := Vector2(npc.casa) + Vector2(0.5, 0.5)
		_comprobar("recupera la posición exacta del NPC",
			npc.pos_tile.is_equal_approx(esperado), "%s vs %s" % [npc.pos_tile, esperado])
		_comprobar("recupera la dirección del NPC",
			npc.direccion.is_equal_approx(Vector2.RIGHT))
		_comprobar("recupera la tarea del NPC", npc.tarea == Pirata.Tarea.DURMIENDO)
		_comprobar("la identidad del NPC sigue siendo estable",
			npc.identidad != null and npc.identidad.instancia.begins_with("npc_"))
		_comprobar("NpcsMundo expone el estado plano cargado",
			NpcsMundo.estado(npc.identidad.instancia).has("pos_tile"))
	Guardado.borrar(RANURA)
	print("=== %d/%d comprobaciones de persistencia NPC ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _barbanegra(mundo: Mundo) -> Pirata:
	for npc in mundo.piratas:
		if npc.id_personaje == "barbanegra":
			return npc
	return null

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s %s" % [nombre, detalle])
