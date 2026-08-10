extends Resource

## Regla de simulacion para una necesidad individual de un NPC.
## Los valores son puntos por hora de juego; el actor solo aplica la regla.

@export var id: String = ""
@export var nombre: String = ""
@export var valor_inicial: float = 100.0
@export var cambio_base_por_hora: float = 0.0
@export var cambios_por_actividad: Dictionary = {}

static func desde_dic(d: Dictionary):
	var n = load("res://scripts/datos/necesidad_data.gd").new()
	n.id = str(d.get("id", ""))
	n.nombre = str(d.get("nombre", n.id))
	n.valor_inicial = float(d.get("valor_inicial", 100.0))
	n.cambio_base_por_hora = float(d.get("cambio_base_por_hora", 0.0))
	n.cambios_por_actividad = (d.get("cambios_por_actividad", {}) as Dictionary).duplicate(true)
	n.resource_name = n.nombre
	return n

func cambio_por_hora(actividad: String) -> float:
	return cambio_base_por_hora + float(cambios_por_actividad.get(actividad, 0.0))
