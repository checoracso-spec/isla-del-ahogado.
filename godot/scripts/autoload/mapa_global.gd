extends Node
const RutaGlobalDataScript := preload("res://scripts/datos/ruta_global_data.gd")
const ZonaRemotaScript := preload("res://scripts/mapa/zona_remota.gd")
## AUTOLOAD: MapaGlobal
##
## Simula la capa estratégica sin cargar todavía escenas locales. Cada destino
## tendrá más adelante una Zona propia; aquí sólo se conserva dónde está el
## jugador y qué viaje está en curso.

signal viaje_iniciado(ruta: Resource, llegada: float)
signal viaje_completado(destino_id: String)
signal viaje_cancelado()

var ubicacion_actual: String = "isla_principal"
var viaje_activo: Dictionary = {}

func _ready() -> void:
	Guardado.registrar("mapa_global", _serializar, _cargar)

func destino(id: String) -> Resource:
	return BaseDeDatos.destino(id)

## Fábrica provisional: cada destino se convierte en una Zona con el mismo
## contrato que la isla y los interiores. No carga escenas ni arte definitivo.
func crear_zona(destino_id: String, ancho: int = 0, alto: int = 0) -> Zona:
	var datos := BaseDeDatos.destino(destino_id)
	if datos == null:
		return null
	if ancho <= 0:
		ancho = datos.ancho
	if alto <= 0:
		alto = datos.alto
	var zona = ZonaRemotaScript.new()
	zona.construir(destino_id, ancho, alto)
	return zona

func destinos() -> Array:
	var ids := BaseDeDatos.destinos.keys()
	ids.sort()
	return ids

func rutas_desde(origen: String = ubicacion_actual) -> Array:
	var resultado: Array = []
	for ruta in BaseDeDatos.rutas.values():
		if ruta.origen == origen:
			resultado.append(ruta)
	resultado.sort_custom(func(a, b): return a.id < b.id)
	return resultado

func ruta(id: String) -> Resource:
	return BaseDeDatos.ruta(id)

func viajando() -> bool:
	return not viaje_activo.is_empty()

func iniciar_viaje(ruta_id: String, barco_id: String = "") -> bool:
	if viajando():
		return false
	var ruta_elegida := ruta(ruta_id)
	if ruta_elegida == null or ruta_elegida.origen != ubicacion_actual:
		return false
	var barco_final := barco_id
	if barco_final == "":
		barco_final = FlotaMundo.disponible_para(
			str(ruta_elegida.barco_requerido), str(ruta_elegida.origen))
	if barco_final == "":
		return false
	var ahora := _hora_total()
	if not FlotaMundo.despachar(barco_final, str(ruta_elegida.origen),
			str(ruta_elegida.destino)):
		return false
	viaje_activo = {
		"ruta_id": ruta_elegida.id,
		"origen": ruta_elegida.origen,
		"destino": ruta_elegida.destino,
		"barco_id": barco_final,
		"barco": barco_final,
		"salida": ahora,
		"llegada": ahora + float(ruta_elegida.dias) * 24.0,
	}
	viaje_iniciado.emit(ruta_elegida, float(viaje_activo["llegada"]))
	return true

func cancelar_viaje() -> bool:
	if not viajando():
		return false
	var barco_id := str(viaje_activo.get("barco_id", viaje_activo.get("barco", "")))
	FlotaMundo.cancelar(barco_id, str(viaje_activo.get("origen", ubicacion_actual)))
	viaje_activo.clear()
	viaje_cancelado.emit()
	return true

func _process(_delta: float) -> void:
	if not viajando():
		return
	if _hora_total() < float(viaje_activo.get("llegada", INF)):
		return
	var destino_id := str(viaje_activo.get("destino", ""))
	var barco_id := str(viaje_activo.get("barco_id", viaje_activo.get("barco", "")))
	ubicacion_actual = destino_id
	FlotaMundo.llegar(barco_id, destino_id)
	viaje_activo.clear()
	viaje_completado.emit(destino_id)

func _hora_total() -> float:
	return float(Reloj.dia * 24) + Reloj.hora

func _serializar() -> Dictionary:
	return {
		"ubicacion_actual": ubicacion_actual,
		"viaje_activo": viaje_activo.duplicate(true),
	}

func _cargar(datos: Dictionary) -> void:
	ubicacion_actual = str(datos.get("ubicacion_actual", "isla_principal"))
	viaje_activo = (datos.get("viaje_activo", {}) as Dictionary).duplicate(true)
	# Partidas anteriores guardaban el tipo en `barco`; desde ahora guardamos la
	# instancia. Si existe una partida vieja, resolvemos su barco estable sin
	# invalidar el viaje guardado.
	if not viaje_activo.is_empty() and not viaje_activo.has("barco_id"):
		var tipo_antiguo := str(viaje_activo.get("barco", ""))
		var origen := str(viaje_activo.get("origen", ubicacion_actual))
		var instancia := FlotaMundo.disponible_para(tipo_antiguo, origen)
		if instancia != "":
			FlotaMundo.despachar(instancia, origen,
				str(viaje_activo.get("destino", "")))
			viaje_activo["barco_id"] = instancia
			viaje_activo["barco"] = instancia
	if not viaje_activo.is_empty() and viaje_activo.has("barco_id"):
		var barco_guardado := str(viaje_activo.get("barco_id", ""))
		var estado_barco := FlotaMundo.estado(barco_guardado)
		if not estado_barco.is_empty() and str(estado_barco.get("estado", "")) != "mar":
			FlotaMundo.despachar(barco_guardado,
				str(viaje_activo.get("origen", ubicacion_actual)),
				str(viaje_activo.get("destino", "")))

func reiniciar() -> void:
	ubicacion_actual = "isla_principal"
	viaje_activo.clear()
	FlotaMundo.reiniciar()
