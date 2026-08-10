class_name FuenteRecursoData
extends Resource
## Definición data-driven de una fuente recolectable del mundo.
##
## No conoce nodos, posiciones ni jugadores. Describe qué produce y cómo se
## regenera; el estado de una instancia vive en RecursosMundo.

@export var id: String = ""
@export var nombre: String = ""
@export var tipo: String = "recurso"       ## naufragio | arbol | veta | cultivo
@export var zona: String = "isla"
@export var productos: Dictionary = {}      ## item_id -> unidades por ciclo
@export var ciclos_maximos: int = 1
@export var regeneracion_horas: float = 24.0
@export var tiempo_recoleccion: float = 0.0

static func desde_dic(d: Dictionary) -> FuenteRecursoData:
	var f := FuenteRecursoData.new()
	f.id = str(d.get("id", ""))
	f.nombre = str(d.get("nombre", f.id))
	f.tipo = str(d.get("tipo", "recurso"))
	f.zona = str(d.get("zona", "isla"))
	f.productos = (d.get("productos", {}) as Dictionary).duplicate(true)
	f.ciclos_maximos = maxi(1, int(d.get("ciclos_maximos", 1)))
	f.regeneracion_horas = maxf(0.0, float(d.get("regeneracion_horas", 24.0)))
	f.tiempo_recoleccion = maxf(0.0, float(d.get("tiempo_recoleccion", 0.0)))
	f.resource_name = f.nombre
	return f
