class_name EdificioData
extends Resource

## Una estructura del asentamiento.
## rol: produccion | comercio | servicio | gestion | vivienda | recoleccion | defensa

@export var id: String = ""
@export var nombre: String = ""
@export var rol: String = "produccion"
@export var trabajadores_max: int = 2
@export var coste: Dictionary = {}           ## id_item -> cantidad para construirlo
@export var recetas: Array[String] = []      ## ids de RecetaData que puede ejecutar
@export var descripcion: String = ""
## Id del InteriorDefinicion al que lleva su puerta. Vacío = no se puede entrar.
@export var interior: String = ""
## Clave base en el manifiesto de assets, p. ej. "edificio.kit_casa".
## Vacío = usa el arte antiguo por rutas. Es lo que permite migrar el arte
## edificio a edificio, por datos, sin un solo `if edificio == "herreria"`.
@export var asset_exterior: String = ""

static func desde_dic(d: Dictionary) -> EdificioData:
	var e := EdificioData.new()
	e.id = d.get("id", "")
	e.nombre = d.get("nombre", e.id)
	e.rol = d.get("rol", "produccion")
	e.trabajadores_max = int(d.get("trabajadores", 2))
	e.coste = d.get("coste", {}).duplicate(true)
	var rs: Array[String] = []
	for r in d.get("recetas", []):
		rs.append(str(r))
	e.recetas = rs
	e.descripcion = d.get("desc", "")
	e.interior = str(d.get("interior", ""))
	e.asset_exterior = str(d.get("asset_exterior", ""))
	e.resource_name = e.nombre
	return e
