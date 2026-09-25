extends Node
## Prueba enfocada de MAREA-014: dos misiones de taberna independientes.

const MISION_CALICO := "marea_009_naufragio"
const MISION_BLACK_SAM := "marea_014_raciones_tripulacion"
const RANURA := 14

var correctas := 0
var fallos := 0
var mundo: Mundo

func _ready() -> void:
	if not _perfil_de_prueba_aislado():
		push_error("MAREA-014 requiere un APPDATA temporal aislado; ejecuta tools/run-tests.ps1.")
		get_tree().quit(1)
		return
	Guardado.borrar(RANURA)
	Misiones.reiniciar()
	Bolsa.mochila.vaciar()
	Bolsa.oro = 0

	var escena: PackedScene = load("res://escenas/mundo.tscn")
	mundo = escena.instantiate() as Mundo
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	Reloj.pausado = true
	_ejecutar()

	if Interiores.dentro():
		Interiores.salir(mundo.jugador)
	Guardado.borrar(RANURA)
	print("=== %d/%d comprobaciones de MAREA-014 ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	var calico := _npc("calico_jack")
	var black_sam := _npc("black_sam")
	_comprobar("existe Calico Jack", calico != null)
	_comprobar("existe Black Sam", black_sam != null)
	if calico == null or black_sam == null:
		return

	var dialogo_calico := calico.get_node_or_null("DialogoNpcTaberna") as DialogoNpcTaberna
	var dialogo_black_sam := black_sam.get_node_or_null("DialogoNpcTaberna") as DialogoNpcTaberna
	_comprobar("Calico usa el diálogo genérico", dialogo_calico != null)
	_comprobar("Black Sam usa el diálogo genérico", dialogo_black_sam != null)
	if dialogo_calico == null or dialogo_black_sam == null:
		return

	_comprobar("ambas definiciones son tipadas",
		BaseDeDatos.mision(MISION_CALICO) is MisionData
		and BaseDeDatos.mision(MISION_BLACK_SAM) is MisionData)
	var definicion_calico: MisionData = BaseDeDatos.mision(MISION_CALICO)
	var definicion_black_sam: MisionData = BaseDeDatos.mision(MISION_BLACK_SAM)
	_comprobar("ambas misiones empiezan disponibles",
		Misiones.estado(MISION_CALICO) == Misiones.QuestState.AVAILABLE
		and Misiones.estado(MISION_BLACK_SAM) == Misiones.QuestState.AVAILABLE)
	_comprobar("Calico se puede aceptar primero",
		Misiones.puede_aceptar(MISION_CALICO))
	_comprobar("Black Sam está bloqueado hasta entregar a Calico",
		not Misiones.puede_aceptar(MISION_BLACK_SAM)
		and not Misiones.aceptar(MISION_BLACK_SAM))
	_comprobar("el bloqueo no cambia el estado de Black Sam",
		Misiones.estado(MISION_BLACK_SAM) == Misiones.QuestState.AVAILABLE)
	_comprobar("el indicador de interacción explica el bloqueo",
		"bloqueado" in dialogo_black_sam.texto_accion().to_lower())
	var textos_bloqueo: Array[String] = []
	dialogo_black_sam.dialogo_mostrado.connect(func(texto: String): textos_bloqueo.append(texto))
	dialogo_black_sam.interactuar(mundo.jugador)
	_comprobar("Black Sam explica que primero hay que completar a Calico",
		not textos_bloqueo.is_empty()
		and "Restos del Naufragio" in textos_bloqueo[0])
	mundo.panel_diario_misiones.abrir()
	var etiqueta_resumen := mundo.panel_diario_misiones.find_child("ResumenMisiones", true, false) as Label
	var resumen_diario := etiqueta_resumen.text if etiqueta_resumen != null else ""
	_comprobar("el diario muestra el requisito de Black Sam",
		"Bloqueada" in resumen_diario and "Restos del Naufragio" in resumen_diario)
	mundo.panel_diario_misiones.cerrar_panel()

	# Calico: aceptar, completar y entregar no altera el estado de Black Sam.
	dialogo_calico.interactuar(mundo.jugador)
	_comprobar("Calico acepta su misión", Misiones.estado(MISION_CALICO) == Misiones.QuestState.ACCEPTED)
	_comprobar("Black Sam sigue disponible", Misiones.estado(MISION_BLACK_SAM) == Misiones.QuestState.AVAILABLE)
	Bolsa.mochila.anadir("madera_naufragio", 2)
	_comprobar("Calico completa el objetivo", Misiones.estado(MISION_CALICO) == Misiones.QuestState.OBJECTIVE_COMPLETE)
	var oro_antes_calico := Bolsa.oro
	dialogo_calico.interactuar(mundo.jugador)
	_comprobar("Calico queda entregada", Misiones.estado(MISION_CALICO) == Misiones.QuestState.TURNED_IN)
	_comprobar("Calico paga una vez",
		Bolsa.oro == oro_antes_calico + definicion_calico.recompensa_doblones)
	var oro_despues_calico := Bolsa.oro
	dialogo_calico.interactuar(mundo.jugador)
	_comprobar("Calico no duplica la recompensa", Bolsa.oro == oro_despues_calico)

	# Black Sam: su propia misión sigue una transición y recompensa separadas.
	_comprobar("entregar a Calico desbloquea a Black Sam",
		Misiones.puede_aceptar(MISION_BLACK_SAM))
	dialogo_black_sam.interactuar(mundo.jugador)
	_comprobar("Black Sam acepta su misión", Misiones.estado(MISION_BLACK_SAM) == Misiones.QuestState.ACCEPTED)
	_comprobar("Calico sigue entregada", Misiones.estado(MISION_CALICO) == Misiones.QuestState.TURNED_IN)
	Bolsa.mochila.anadir("raciones", 3)
	_comprobar("Black Sam completa el objetivo", Misiones.estado(MISION_BLACK_SAM) == Misiones.QuestState.OBJECTIVE_COMPLETE)
	var oro_antes_black_sam := Bolsa.oro
	dialogo_black_sam.interactuar(mundo.jugador)
	_comprobar("Black Sam queda entregada", Misiones.estado(MISION_BLACK_SAM) == Misiones.QuestState.TURNED_IN)
	_comprobar("Black Sam paga una vez",
		Bolsa.oro == oro_antes_black_sam + definicion_black_sam.recompensa_doblones)
	var oro_despues_black_sam := Bolsa.oro
	dialogo_black_sam.interactuar(mundo.jugador)
	_comprobar("Black Sam no duplica la recompensa", Bolsa.oro == oro_despues_black_sam)

	_comprobar("guarda ambas misiones con Guardado", Guardado.guardar(RANURA))
	var ids_antes := Misiones.ids()
	Misiones.reiniciar()
	Bolsa.oro = 0
	_comprobar("limpia ambas misiones antes de cargar",
		Misiones.ids().is_empty() and Bolsa.oro == 0)
	_comprobar("carga ambas misiones con Guardado", Guardado.cargar(RANURA))
	_comprobar("restaura los dos IDs", Misiones.ids() == ids_antes)
	_comprobar("restaura ambos estados entregados",
		Misiones.estado(MISION_CALICO) == Misiones.QuestState.TURNED_IN
		and Misiones.estado(MISION_BLACK_SAM) == Misiones.QuestState.TURNED_IN)
	_comprobar("restaura las dos recompensas",
		Bolsa.oro == definicion_calico.recompensa_doblones + definicion_black_sam.recompensa_doblones)

func _npc(id: String) -> Pirata:
	for npc: Pirata in mundo.piratas:
		if npc.id_personaje == id:
			return npc
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
	var ruta_partida := ProjectSettings.globalize_path(Guardado.ruta(RANURA)) \
		.replace("\\", "/").to_lower()
	return not raiz_temporal.is_empty() and ruta_partida.begins_with(raiz_temporal + "/")
