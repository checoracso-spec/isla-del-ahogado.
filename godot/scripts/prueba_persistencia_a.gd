extends Node
## PROCESO A de la prueba de persistencia real.
##
## Monta el mundo, entra en una casa, vacía el cofre, deja un estado concreto
## y guarda. No comprueba nada: sólo deja la partida escrita en disco y sale.
## Quien comprueba es el proceso B, arrancado desde cero.
##
## Existe porque guardar y cargar dentro del MISMO proceso no demuestra que la
## partida esté completa: cualquier dato que siguiera vivo en memoria taparía
## el agujero.

const D := preload("res://scripts/prueba_persistencia_datos.gd")

func _ready() -> void:
	print("\n=== PERSISTENCIA · PROCESO A (escribe) ===\n")
	var escena: PackedScene = load("res://escenas/mundo.tscn")
	var mundo: Mundo = escena.instantiate() as Mundo
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	Reloj.pausado = true

	Guardado.borrar(D.RANURA)
	Almacen.anadir("tablon_tratado", MuelleManager.COSTE_TABLONES, "prueba_red_muelle")
	if not MuelleManager.grua_activa and not MuelleManager.activar_grua():
		printerr("A: no se pudo instalar la red del muelle")
		get_tree().quit(1)
		return
	print("  red muelle  : instalada")

	if mundo.puertas.is_empty():
		printerr("A: el mundo no generó puertas")
		get_tree().quit(1)
		return

	var puerta: Puerta = mundo.puertas[0]
	print("  puerta      : %s (edificio %s)" % [puerta.identidad.instancia, puerta.edificio_instancia])
	print("  casilla ext : %s" % puerta.casilla_exterior)

	# Agotar una fuente y sembrar una parcela antes del cierre. El proceso B
	# comprobará que no se reconstruyen desde su estado inicial.
	var semillero = null
	var parcela = null
	for fuente in mundo.fuentes_recurso:
		if fuente.definicion_id == D.FUENTE_GUARDADA:
			semillero = fuente
	for candidata in mundo.parcelas_cultivo:
		if candidata.definicion_id == D.CULTIVO_GUARDADO:
			parcela = candidata
	if semillero == null or parcela == null:
		printerr("A: faltan fuente o parcela para persistencia")
		get_tree().quit(1)
		return
	Bolsa.mochila.vaciar()
	semillero.interactuar(mundo.jugador)
	parcela.interactuar(mundo.jugador)
	print("  semillero   : %d ciclos restantes" % semillero.cantidad())
	print("  parcela      : etapa %d" % CultivosMundo.etapa(parcela.identidad.instancia))

	# Entrar y vaciar el cofre
	mundo.recibir_jugador(mundo.jugador, Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5))
	if not Interiores.entrar(puerta, mundo.jugador):
		printerr("A: no se pudo entrar")
		get_tree().quit(1)
		return
	if Interiores.activo.cofres.is_empty():
		printerr("A: el interior no tiene cofre")
		get_tree().quit(1)
		return
	var cofre: Cofre = Interiores.activo.cofres[0]
	print("  cofre       : %s con %d ron" % [cofre.identidad.instancia,
		cofre.inventario().cantidad("ron")])

	Bolsa.mochila.vaciar()
	cofre.inventario().transferir_a(Bolsa.mochila, "ron", D.RON_EN_MOCHILA)

	# La partida se guarda en otra zona del mismo edificio. Esto demuestra que
	# al reiniciar no se reconstruye siempre la planta baja por comodidad.
	var subida := Interiores.activo.actores.get_node_or_null(
		"Mueble_escalera_7_3") as Interactuable
	if subida == null:
		printerr("A: no existe la escalera de subida")
		get_tree().quit(1)
		return
	subida.interactuar(mundo.jugador)
	if not Interiores.dentro() or Ubicacion.zona != D.ZONA_INTERIOR:
		printerr("A: no se pudo subir a %s" % D.ZONA_INTERIOR)
		get_tree().quit(1)
		return

	# Estado concreto y posición fija dentro
	mundo.jugador.colocar(D.POS_INTERIOR)
	Ubicacion.anotar(mundo.jugador.pos_tile, mundo.jugador.direccion)
	Bolsa.oro = D.ORO
	Bolsa.salud = D.SALUD
	Bolsa.energia = D.ENERGIA
	Reloj.dia = D.DIA
	Reloj.hora = D.HORA
	MapaGlobal.reiniciar()
	if not MapaGlobal.iniciar_viaje(D.RUTA_GLOBAL_GUARDADA):
		printerr("A: no se pudo iniciar el viaje global de prueba")
		get_tree().quit(1)
		return
	print("  viaje global: %s -> %s" % [MapaGlobal.ubicacion_actual, D.DESTINO_GLOBAL_GUARDADO])

	if not Guardado.guardar(D.RANURA):
		printerr("A: no se pudo guardar")
		get_tree().quit(1)
		return

	print("  guardado en : %s" % Guardado.ruta(D.RANURA))
	print("  zona        : %s" % Ubicacion.zona)
	print("  posicion    : %s" % Ubicacion.pos)
	print("\nA: LISTO\n")
	get_tree().quit(0)
