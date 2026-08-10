extends Resource

## Definición data-driven de un evento temporal del mundo.
## Los efectos son datos planos para que futuras reglas puedan consumirlos sin
## que el evento conozca edificios, barcos o nodos concretos.

@export var id: String = ""
@export var nombre: String = ""
@export var tipo: String = "mundo" ## clima | bloqueo | escasez | naufragio
@export var duracion_horas: float = 24.0
@export var multiplicadores_oferta: Dictionary = {}
@export var multiplicador_riesgo_viaje: float = 1.0
@export var descripcion: String = ""

static func desde_dic(d: Dictionary):
	var e = load("res://scripts/datos/evento_mundo_data.gd").new()
	e.id = str(d.get("id", ""))
	e.nombre = str(d.get("nombre", e.id))
	e.tipo = str(d.get("tipo", "mundo"))
	e.duracion_horas = maxf(0.1, float(d.get("duracion_horas", 24.0)))
	e.multiplicadores_oferta = (d.get("multiplicadores_oferta", {}) as Dictionary).duplicate(true)
	e.multiplicador_riesgo_viaje = maxf(0.0, float(d.get("multiplicador_riesgo_viaje", 1.0)))
	e.descripcion = str(d.get("desc", ""))
	e.resource_name = e.nombre
	return e
