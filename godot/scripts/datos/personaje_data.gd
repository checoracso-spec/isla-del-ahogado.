class_name PersonajeData
extends Resource

## Un corsario reclutable. La habilidad pasiva NO es texto decorativo:
## "efecto" es lo que el código lee de verdad, vía Plantel.modificador().
##
## Formato de efecto: { "tipo": "consumo_ron", "valor": -0.30, "ambito": "taberna" }
##   tipo   -> qué toca (ver Plantel.gd para la lista completa)
##   valor  -> fracción (-0.30 = 30% menos) o número absoluto según el tipo
##   ambito -> "" para global, o el id de un edificio concreto

@export var id: String = ""
@export var nombre: String = ""
@export var titulo: String = ""
@export var rol: String = ""
@export var habilidad: String = ""           ## descripción legible para la UI
@export var efecto: Dictionary = {}
@export var efecto_extra: Dictionary = {}    ## para los que tienen contrapartida (Stede Bonnet)
@export var historico: bool = true
@export var horario_id: String = "tripulacion"

static func desde_dic(d: Dictionary) -> PersonajeData:
	var p := PersonajeData.new()
	p.id = d.get("id", "")
	p.nombre = d.get("nombre", p.id)
	p.titulo = d.get("titulo", "")
	p.rol = d.get("rol", "")
	p.habilidad = d.get("habilidad", "")
	p.efecto = d.get("efecto", {}).duplicate(true)
	p.efecto_extra = d.get("efecto_extra", {}).duplicate(true)
	p.historico = bool(d.get("historico", true))
	p.horario_id = str(d.get("horario", "tripulacion"))
	p.resource_name = p.nombre
	return p
