extends Node
## AUTOLOAD: CraftingManager
##
## Fabricación manual del jugador. Trabaja exclusivamente con Bolsa.mochila;
## Almacen conserva su cadena automática y su API intactas.

signal estacion_abierta(estacion_id: String)
signal estacion_cerrada()
signal actualizada()
signal fabricacion_iniciada(receta_id: String)
signal fabricacion_completada(receta_id: String, productos: Dictionary, calidad: float)
signal fallo(mensaje: String)

var estacion_id_actual: String = ""
var horario_id_actual: String = ""
var actividades_productivas: Array = ["trabajar"]
var actividades_preparacion: Array = []
var trabajo: Dictionary = {}

func _ready() -> void:
	Guardado.registrar("crafting", _serializar, _cargar)

func abrir(estacion_id: String, _quien: Node = null, horario_id: String = "",
		productivas: Array = ["trabajar"], preparacion: Array = []) -> void:
	if recetas_para(estacion_id).is_empty():
		fallo.emit("Esta estación no tiene recetas disponibles.")
		return
	estacion_id_actual = estacion_id
	horario_id_actual = horario_id
	actividades_productivas = productivas
	actividades_preparacion = preparacion
	estacion_abierta.emit(estacion_id)
	actualizada.emit()

func cerrar() -> void:
	estacion_id_actual = ""
	horario_id_actual = ""
	estacion_cerrada.emit()
	actualizada.emit()

func cancelar() -> void:
	if trabajo.is_empty():
		return
	trabajo.clear()
	actualizada.emit()

func recetas_para(id_estacion: String) -> Array[RecetaData]:
	var resultado: Array[RecetaData] = []
	for receta: RecetaData in BaseDeDatos.recetas.values():
		if receta.estacion == id_estacion:
			resultado.append(receta)
	resultado.sort_custom(func(a: RecetaData, b: RecetaData) -> bool: return a.nombre < b.nombre)
	return resultado

func receta_actual(id_receta: String) -> RecetaData:
	return BaseDeDatos.receta(id_receta)

## Comprueba materiales, energía y espacio sin modificar la mochila.
func puede_fabricar(id_receta: String) -> Dictionary:
	var receta := receta_actual(id_receta)
	if receta == null:
		return {"ok": false, "motivo": "Receta desconocida."}
	if receta.estacion != estacion_id_actual:
		return {"ok": false, "motivo": "Usa la estación correcta."}
	if not en_horario():
		return {"ok": false, "motivo": "La estacion esta cerrada por horario."}
	if not trabajo.is_empty():
		return {"ok": false, "motivo": "La estación está ocupada."}
	if Bolsa.energia < receta.energia:
		return {"ok": false, "motivo": "Falta energía."}

	var simulacion := Inventario.new()
	simulacion.capacidad = Bolsa.mochila.capacidad
	simulacion.cargar(Bolsa.mochila.serializar())
	var gasto: Dictionary = simulacion.consumir_con_sustitutos(receta.insumos, receta.sustitutos)
	if not gasto.get("ok", false):
		var faltan: Array[String] = []
		for id in gasto.get("faltan", {}):
			faltan.append("%d× %s" % [int(gasto["faltan"][id]), BaseDeDatos.nombre_item(str(id))])
		return {"ok": false, "motivo": "Falta " + ", ".join(faltan)}

	for id in receta.productos:
		var cantidad_salida := maxi(1, int(round(int(receta.productos[id]) * float(gasto.get("calidad", 1.0)))))
		if simulacion.hueco_para(str(id)) < cantidad_salida:
			return {"ok": false, "motivo": "La mochila no tiene espacio."}
		if simulacion.anadir(str(id), cantidad_salida) < cantidad_salida:
			return {"ok": false, "motivo": "La mochila no tiene espacio."}
	return {"ok": true, "motivo": "Listo", "calidad": float(gasto.get("calidad", 1.0))}

func fabricar(id_receta: String) -> bool:
	var validacion := puede_fabricar(id_receta)
	if not validacion.get("ok", false):
		fallo.emit(str(validacion.get("motivo", "No se puede fabricar.")))
		return false
	var receta := receta_actual(id_receta)
	var gasto := Bolsa.mochila.consumir_con_sustitutos(receta.insumos, receta.sustitutos)
	if not gasto.get("ok", false):
		fallo.emit("Los materiales cambiaron antes de iniciar.")
		return false
	Bolsa.ajustar_energia(-receta.energia)
	trabajo = {
		"receta_id": receta.id,
		"progreso": 0.0,
		"calidad": float(gasto.get("calidad", 1.0)),
	}
	fabricacion_iniciada.emit(receta.id)
	actualizada.emit()
	return true

## Trasvasa materiales desde la logística del asentamiento a la mochila.
## Es una operación explícita; no hace que una receta lea Almacen directamente.
func abastecer(id_receta: String) -> Dictionary:
	var receta := receta_actual(id_receta)
	if receta == null:
		return {"ok": false, "movidos": {}, "motivo": "Receta desconocida."}
	if not en_horario():
		return {"ok": false, "movidos": {}, "motivo": "La estacion esta cerrada por horario."}
	if not trabajo.is_empty():
		return {"ok": false, "movidos": {}, "motivo": "La estación está ocupada."}
	var movidos: Dictionary = {}
	for id in receta.insumos:
		var necesario := int(receta.insumos[id])
		var falta := maxi(0, necesario - Bolsa.mochila.cantidad(str(id)))
		if falta <= 0:
			continue
		var movido := Bolsa.retirar_del_almacen(str(id), falta)
		if movido > 0:
			movidos[str(id)] = movido

	# Si el original no estaba disponible, intenta traer también el sustituto.
	for id in receta.insumos:
		var falta := maxi(0, int(receta.insumos[id]) - Bolsa.mochila.cantidad(str(id)))
		if falta <= 0 or not receta.sustitutos.has(id):
			continue
		var s: Dictionary = receta.sustitutos[id]
		var sid := str(s.get("id", ""))
		var cantidad_sustituto := int(ceil(falta * maxf(0.0001, float(s.get("ratio", 1.0)))))
		var movido_sustituto := Bolsa.retirar_del_almacen(sid, cantidad_sustituto)
		if movido_sustituto > 0:
			movidos[sid] = int(movidos.get(sid, 0)) + movido_sustituto

	var hubo := not movidos.is_empty()
	var motivo := "Materiales trasladados a la mochila." if hubo else "No hay esos materiales en el almacén."
	actualizada.emit()
	return {"ok": hubo, "movidos": movidos, "motivo": motivo}

func trabajando() -> bool:
	return not trabajo.is_empty()

func estado_operativo() -> String:
	if horario_id_actual == "":
		return "abierta"
	var horario: HorarioData = BaseDeDatos.horario(horario_id_actual)
	return horario.estado_en(Reloj.hora, actividades_productivas, actividades_preparacion) if horario != null else "detenida"

func en_horario() -> bool:
	return estado_operativo() == "abierta"

func porcentaje() -> float:
	if trabajo.is_empty():
		return 0.0
	var receta := receta_actual(str(trabajo.get("receta_id", "")))
	if receta == null or receta.segundos <= 0.0:
		return 0.0
	return clampf(float(trabajo.get("progreso", 0.0)) / receta.segundos, 0.0, 1.0)

func _process(delta: float) -> void:
	if trabajo.is_empty() or Reloj.pausado or not en_horario():
		return
	var receta := receta_actual(str(trabajo.get("receta_id", "")))
	if receta == null:
		trabajo.clear()
		actualizada.emit()
		return
	trabajo["progreso"] = float(trabajo.get("progreso", 0.0)) + delta
	if float(trabajo["progreso"]) < receta.segundos:
		actualizada.emit()
		return

	var calidad := float(trabajo.get("calidad", 1.0))
	var salida: Dictionary = {}
	for id in receta.productos:
		var cantidad_salida := maxi(1, int(round(int(receta.productos[id]) * calidad)))
		var aceptado := Bolsa.mochila.anadir(str(id), cantidad_salida)
		if aceptado > 0:
			salida[str(id)] = aceptado
	trabajo.clear()
	fabricacion_completada.emit(receta.id, salida, calidad)
	actualizada.emit()

func _serializar() -> Dictionary:
	return {
		"estacion_id": estacion_id_actual,
		"horario_id": horario_id_actual,
		"actividades_productivas": actividades_productivas,
		"actividades_preparacion": actividades_preparacion,
		"trabajo": trabajo.duplicate(true),
	}

func _cargar(datos: Dictionary) -> void:
	estacion_id_actual = str(datos.get("estacion_id", ""))
	horario_id_actual = str(datos.get("horario_id", ""))
	actividades_productivas = datos.get("actividades_productivas", ["trabajar"])
	actividades_preparacion = datos.get("actividades_preparacion", [])
	var guardado: Variant = datos.get("trabajo", {})
	trabajo = (guardado as Dictionary).duplicate(true) if guardado is Dictionary else {}
	actualizada.emit()
