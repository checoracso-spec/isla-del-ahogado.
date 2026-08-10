class_name CultivoData
extends Resource

## Definición de cultivo. No conoce parcelas ni jugadores.
## El estado de cada parcela vive en CultivosMundo.

@export var id: String = ""
@export var nombre: String = ""
@export var semilla: String = ""
@export var cosecha: Dictionary = {}
@export var horas_crecimiento: float = 24.0
@export var fertilizante: String = "fertilizante"
@export var tipo: String = "cultivo"
@export var automatizador_edificio: String = ""
@export var automatizador_trabajadores: int = 0
@export var automatizador_horario_id: String = ""

static func desde_dic(d: Dictionary) -> CultivoData:
	var c := CultivoData.new()
	c.id = str(d.get("id", ""))
	c.nombre = str(d.get("nombre", c.id))
	c.semilla = str(d.get("semilla", ""))
	c.cosecha = (d.get("cosecha", {}) as Dictionary).duplicate(true)
	c.horas_crecimiento = maxf(0.1, float(d.get("horas_crecimiento", 24.0)))
	c.fertilizante = str(d.get("fertilizante", "fertilizante"))
	c.tipo = str(d.get("tipo", "cultivo"))
	c.automatizador_edificio = str(d.get("automatizador_edificio", ""))
	c.automatizador_trabajadores = maxi(0, int(d.get("automatizador_trabajadores", 0)))
	c.automatizador_horario_id = str(d.get("automatizador_horario_id", ""))
	c.resource_name = c.nombre
	return c
