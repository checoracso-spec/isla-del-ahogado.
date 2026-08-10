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
func crear_zona(destino_id: String, ancho: int = 16, alto: int = 12) -> Zona:
	var datos := BaseDeDatos.destino(destino_id)
	if datos == null:
		return null
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
	var barco_final: String = barco_id if barco_id != "" else str(ruta_elegida.barco_requerido)
	var ahora := _hora_total()
	viaje_activo = {
		"ruta_id": ruta_elegida.id,
		"origen": ruta_elegida.origen,
		"destino": ruta_elegida.destino,
		"barco": barco_final,
		"salida": ahora,
		"llegada": ahora + float(ruta_elegida.dias) * 24.0,
	}
	viaje_iniciado.emit(ruta_elegida, float(viaje_activo["llegada"]))
	return true

func cancelar_viaje() -> bool:
	if not viajando():
		return false
	viaje_activo.clear()
	viaje_cancelado.emit()
	return true

func _process(_delta: float) -> void:
	if not viajando():
		return
	if _hora_total() < float(viaje_activo.get("llegada", INF)):
		return
	var destino_id := str(viaje_activo.get("destino", ""))
	ubicacion_actual = destino_id
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

func reiniciar() -> void:
	ubicacion_actual = "isla_principal"
	viaje_activo.clear()
