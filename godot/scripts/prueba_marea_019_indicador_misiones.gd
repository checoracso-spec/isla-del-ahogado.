extends Node
## Prueba de integración de señales visuales de misión sobre los NPCs.

const MISION_CALICO := "marea_009_naufragio"
const MISION_BLACK_SAM := "marea_014_raciones_tripulacion"

var correctas := 0
var fallos := 0
var mundo: Mundo

func _ready() -> void:
	if not _perfil_de_prueba_aislado():
		push_error("MAREA-019 requiere un perfil APPDATA temporal aislado; ejecuta tools/run-tests.ps1.")
		get_tree().quit(1)
		return
	Misiones.reiniciar()
	Bolsa.mochila.vaciar()
	Bolsa.oro = 0
	var escena: PackedScene = load("res://escenas/mundo.tscn")
	mundo = escena.instantiate() as Mundo
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	Reloj.pausado = true
	await _ejecutar()
	if Interiores.dentro():
		Interiores.salir(mundo.jugador)
	print("=== %d/%d comprobaciones de MAREA-019 ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	var calico := _dialogo_npc("calico_jack")
	var black_sam := _dialogo_npc("black_sam")
	_comprobar("Calico y Black Sam tienen diálogo de misión", calico != null and black_sam != null)
	if calico == null or black_sam == null:
		return
	_comprobar("Calico muestra encargo disponible", calico.estado_marcador() == "disponible")
	_comprobar("Black Sam muestra bloqueo inicial", black_sam.estado_marcador() == "bloqueada")
	_comprobar("ambos marcadores escuchan cambios globales de misión",
		Misiones.estado_cambiado.is_connected(
			Callable(calico, "_al_cambiar_estado_mision"))
		and Misiones.estado_cambiado.is_connected(
			Callable(black_sam, "_al_cambiar_estado_mision")))
	_comprobar("el marcador comparte la posición del NPC y no desplaza sus pies",
		calico.position == Vector2.ZERO and black_sam.position == Vector2.ZERO)

	calico.interactuar(mundo.jugador)
	await get_tree().process_frame
	_comprobar("aceptar oculta el marcador de Calico", calico.estado_marcador() == "oculto")
	_comprobar("aceptar Calico no desbloquea aún a Black Sam",
		black_sam.estado_marcador() == "bloqueada")
	Bolsa.mochila.anadir("madera_naufragio", 2)
	await get_tree().process_frame
	_comprobar("objetivo de Calico muestra marcador de entrega",
		calico.estado_marcador() == "entrega")
	calico.interactuar(mundo.jugador)
	await get_tree().process_frame
	_comprobar("entregar Calico quita su marcador", calico.estado_marcador() == "oculto")
	_comprobar("la señal global desbloquea inmediatamente a Black Sam",
		black_sam.estado_marcador() == "disponible")

	black_sam.interactuar(mundo.jugador)
	await get_tree().process_frame
	_comprobar("aceptar la misión de Black Sam oculta su marcador",
		black_sam.estado_marcador() == "oculto")
	Bolsa.mochila.anadir("raciones", 3)
	await get_tree().process_frame
	_comprobar("objetivo de Black Sam muestra marcador de entrega",
		black_sam.estado_marcador() == "entrega")
	black_sam.interactuar(mundo.jugador)
	await get_tree().process_frame
	_comprobar("entregar a Black Sam oculta su marcador",
		black_sam.estado_marcador() == "oculto")

func _dialogo_npc(id: String) -> DialogoNpcTaberna:
	for npc: Pirata in mundo.piratas:
		if npc.id_personaje == id:
			return npc.get_node_or_null("DialogoNpcTaberna") as DialogoNpcTaberna
	return null

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)

func _perfil_de_prueba_aislado() -> bool:
	var raiz_temporal := OS.get_environment("TEMP").replace("\\", "/").trim_suffix("/").to_lower()
	var ruta_partida := ProjectSettings.globalize_path(Guardado.ruta(14)) \
		.replace("\\", "/").to_lower()
	return not raiz_temporal.is_empty() and ruta_partida.begins_with(raiz_temporal + "/")
