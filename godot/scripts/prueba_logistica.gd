extends Node
## Banco de pruebas de la logística. No forma parte del juego: sirve para
## comprobar de un vistazo que las reglas siguen cumpliéndose después de
## tocar el código.
##
## Cómo ejecutarlo desde la consola (sin abrir el editor):
##   Godot_v4.7.1-stable_win64_console.exe --headless --path <carpeta godot> res://escenas/prueba_logistica.tscn

var fallos := 0
var pruebas := 0

func _ready() -> void:
	print("\n=== PRUEBAS DE LOGÍSTICA ===\n")
	_p1_consumo_normal()
	_p2_sustitucion_completa()
	_p3_sustitucion_parcial()
	_p4_no_gasta_si_falla()
	_p5_cuello_de_botella_una_vez()
	_p6_reservas()
	_p7_motin_sin_raciones()
	_p8_bodega_canones_vs_botin()
	_p9_rastreo_tres_ubicaciones()
	print("\n=== %d/%d correctas ===" % [pruebas - fallos, pruebas])
	get_tree().quit(1 if fallos > 0 else 0)

# ---------------------------------------------------------------------------

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	pruebas += 1
	if condicion:
		print("  OK    %s" % nombre)
	else:
		fallos += 1
		print("  FALLO %s   %s" % [nombre, detalle])

func _limpiar() -> void:
	Almacen.vaciar()
	Plantel.reclutados.clear()
	Plantel.asignaciones.clear()

# ---------------------------------------------------------------------------

func _p1_consumo_normal() -> void:
	print("1. Consumo con material correcto")
	_limpiar()
	Almacen.anadir("acero_imperial", 10)
	Almacen.anadir("carbon", 10)
	Almacen.anadir("aceite_imperial", 10)
	var r := BaseDeDatos.receta("forjar_canon")
	var res := Almacen.consumir(r.insumos, "herreria", r.sustitutos)
	_comprobar("el lote sale adelante", res["ok"])
	_comprobar("calidad intacta (1.0)", is_equal_approx(res["calidad"], 1.0), str(res["calidad"]))
	_comprobar("gastó 3 aceros", Almacen.cantidad("acero_imperial") == 7,
		str(Almacen.cantidad("acero_imperial")))
	_comprobar("no tocó la grasa", Almacen.cantidad("grasa_ballena") == 0)

func _p2_sustitucion_completa() -> void:
	print("2. Bloqueo naval: cero aceite imperial -> grasa de ballena")
	_limpiar()
	Almacen.anadir("acero_imperial", 10)
	Almacen.anadir("carbon", 10)
	Almacen.anadir("grasa_ballena", 10)      # ratio 2:1 -> hacen falta 4
	var r := BaseDeDatos.receta("forjar_canon")
	var res := Almacen.consumir(r.insumos, "herreria", r.sustitutos)
	_comprobar("la herrería NO se para", res["ok"])
	_comprobar("gastó 4 grasas por 2 aceites", Almacen.cantidad("grasa_ballena") == 6,
		str(Almacen.cantidad("grasa_ballena")))
	_comprobar("calidad degradada a 0.65", is_equal_approx(res["calidad"], 0.65), str(res["calidad"]))
	_comprobar("informó de la sustitución", res["sustituciones"].size() == 1)

func _p3_sustitucion_parcial() -> void:
	print("3. Sustitución parcial: hay algo de aceite, pero no basta")
	_limpiar()
	Almacen.anadir("acero_imperial", 10)
	Almacen.anadir("carbon", 10)
	Almacen.anadir("aceite_imperial", 1)     # falta 1 -> 2 grasas
	Almacen.anadir("grasa_ballena", 10)
	var r := BaseDeDatos.receta("forjar_canon")
	var res := Almacen.consumir(r.insumos, "herreria", r.sustitutos)
	_comprobar("sale adelante mezclando", res["ok"])
	_comprobar("agotó el aceite que había", Almacen.cantidad("aceite_imperial") == 0)
	_comprobar("completó con 2 grasas", Almacen.cantidad("grasa_ballena") == 8,
		str(Almacen.cantidad("grasa_ballena")))

func _p4_no_gasta_si_falla() -> void:
	print("4. Si el plan no es viable, no se gasta NADA (nada a medias)")
	_limpiar()
	Almacen.anadir("acero_imperial", 3)
	Almacen.anadir("carbon", 4)
	# sin aceite y sin grasa -> imposible
	var r := BaseDeDatos.receta("forjar_canon")
	var res := Almacen.consumir(r.insumos, "herreria", r.sustitutos)
	_comprobar("devuelve fallo", not res["ok"])
	_comprobar("el acero sigue intacto", Almacen.cantidad("acero_imperial") == 3,
		str(Almacen.cantidad("acero_imperial")))
	_comprobar("el carbón sigue intacto", Almacen.cantidad("carbon") == 4)
	_comprobar("dice qué falta", res["faltan"].has("aceite_imperial"))

func _p5_cuello_de_botella_una_vez() -> void:
	print("5. El aviso de cuello de botella no hace spam")
	_limpiar()
	var avisos := [0]
	var resueltos := [0]
	var f1 := func(_e, _i, _n): avisos[0] += 1
	var f2 := func(_e, _i): resueltos[0] += 1
	Almacen.cuello_de_botella.connect(f1)
	Almacen.cuello_resuelto.connect(f2)

	Almacen.anadir("ron", 10)
	Almacen.vigilar("taberna", "ron", 6)
	_comprobar("con 10 de ron no avisa", avisos[0] == 0)

	Almacen.retirar("ron", 6)                # quedan 4, por debajo de 6
	_comprobar("avisa al bajar del mínimo", avisos[0] == 1, str(avisos[0]))
	Almacen.retirar("ron", 1)                # sigue bajo: no debe repetir
	Almacen.retirar("ron", 1)
	_comprobar("no repite el aviso", avisos[0] == 1, str(avisos[0]))

	Almacen.anadir("ron", 20)
	_comprobar("avisa de que se resolvió", resueltos[0] == 1, str(resueltos[0]))

	Almacen.cuello_de_botella.disconnect(f1)
	Almacen.cuello_resuelto.disconnect(f2)
	Almacen.dejar_de_vigilar("taberna", "ron")

func _p6_reservas() -> void:
	print("6. Una estación no puede robarle el material a otra")
	_limpiar()
	Almacen.anadir("tablon_tratado", 5)
	_comprobar("reserva 4", Almacen.reservar({ "tablon_tratado": 4 }))
	_comprobar("sólo queda 1 disponible", Almacen.disponible("tablon_tratado") == 1,
		str(Almacen.disponible("tablon_tratado")))
	_comprobar("otra estación no puede coger 3",
		not Almacen.consumir({ "tablon_tratado": 3 }, "otra")["ok"])
	Almacen.liberar_reserva({ "tablon_tratado": 4 })
	_comprobar("liberada, vuelve a haber 5", Almacen.disponible("tablon_tratado") == 5)

func _p7_motin_sin_raciones() -> void:
	print("7. Amanecer sin comida ni paga dispara el motín")
	_limpiar()
	Motin.nivel = 10.0
	Motin.tripulacion = 8
	Reloj.nuevo_dia.emit(2)                  # despensa vacía a propósito
	_comprobar("el motín sube", Motin.nivel > 10.0, str(Motin.nivel))
	_comprobar("cruza a tensión o peor", Motin.estado_texto() != "calma", Motin.estado_texto())

	# ahora con Dientes de Oro: la misma hambruna cuesta menos raciones
	_limpiar()
	Almacen.anadir("raciones", 8)
	Almacen.anadir("doblon", 500)
	Plantel.reclutar("dientes_oro")
	Motin.nivel = 40.0
	Reloj.nuevo_dia.emit(3)
	_comprobar("con cocinero y despensa, el motín baja", Motin.nivel < 40.0, str(Motin.nivel))
	_comprobar("sobraron raciones gracias al cocinero", Almacen.cantidad("raciones") > 0,
		str(Almacen.cantidad("raciones")))

func _p8_bodega_canones_vs_botin() -> void:
	print("8. Cañones y botín compiten por la misma bodega")
	_limpiar()
	var carga := { "seda_robada": 20 }
	_comprobar("balandra con 0 cañones: cabe", RastreoCarga.cabe("balandra", carga, 0))
	_comprobar("balandra con 4 cañones: ya no cabe", not RastreoCarga.cabe("balandra", carga, 4))

	Plantel.reclutar("anne_bonny")           # +15% de capacidad
	_comprobar("con Anne Bonny sí cabe algo más",
		RastreoCarga.medir(carga, 4)["volumen"] <= float(RastreoCarga.capacidad("bergantin")["volumen"]))
	_limpiar()

func _p9_rastreo_tres_ubicaciones() -> void:
	print("9. La misma mercancía, localizada en mar / puerto / cofres")
	_limpiar()
	Almacen.anadir("seda_robada", 10)
	Almacen.anadir("canon", 2)               # los cañones también salen de los cofres
	var id := RastreoCarga.zarpar("bergantin", { "seda_robada": 4 }, 2, "Portobello", 3)
	_comprobar("el barco zarpa", id != "")
	_comprobar("los cañones salieron del almacén", Almacen.cantidad("canon") == 0,
		str(Almacen.cantidad("canon")))
	var g: Dictionary = RastreoCarga.inventario_global()
	_comprobar("6 en cofres", int(g["seda_robada"]["cofres"]) == 6, str(g["seda_robada"]))
	_comprobar("4 en el mar", int(g["seda_robada"]["mar"]) == 4, str(g["seda_robada"]))
	_comprobar("el total sigue siendo 10", int(g["seda_robada"]["total"]) == 10)

	for d in range(4):
		RastreoCarga._pasar_dia(d)
		if RastreoCarga.manifiestos.has(id):
			RastreoCarga.manifiestos[id]["interceptado"] = false   # sin azar en la prueba
	if RastreoCarga.manifiestos.has(id):
		g = RastreoCarga.inventario_global()
		_comprobar("al atracar pasa a 'puerto', no a cofres",
			int(g["seda_robada"]["puerto"]) == 4, str(g["seda_robada"]))
		RastreoCarga.descargar(id)
		_comprobar("descargado, vuelven los 10 a los cofres",
			Almacen.cantidad("seda_robada") == 10, str(Almacen.cantidad("seda_robada")))
	else:
		print("  (el barco se perdió por azar; repite la prueba)")
