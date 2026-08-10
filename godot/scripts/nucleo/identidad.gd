class_name Identidad
extends RefCounted
## Quién es esta cosa concreta del mundo.
##
## Distingue dos preguntas que hasta ahora se confundían:
##
##   definicion  →  QUÉ es.      "taberna"      (viene de BaseDeDatos)
##   instancia   →  CUÁL es.     "edificio_0007" (única, para siempre)
##
## Sin esto no puede haber dos tabernas: la segunda pisa a la primera. Y no se
## puede guardar la partida, porque "el cofre de la taberna" no señala a nada
## en concreto.
##
## Va como COMPONENTE y no por herencia a propósito: un edificio es un Node2D,
## el jugador es un Actor y un cofre puede no ser ni un nodo. Todos pueden
## llevar una Identidad dentro; ninguno podría heredar de la misma clase.

## Familias de entidad. Sirven para preguntar "dame todos los barcos".
const TIPOS := ["edificio", "actor", "objeto", "zona", "barco", "animal"]

var tipo: String = ""            ## edificio | actor | objeto | zona | barco | animal
var definicion: String = ""      ## el id en BaseDeDatos: "taberna", "cofre_oxidado"
var instancia: String = ""       ## único e irrepetible: "edificio_0007"
var clave: String = ""           ## clave natural que lo generó; permite reencontrarlo

func _init(p_tipo: String = "", p_definicion: String = "",
		p_instancia: String = "", p_clave: String = "") -> void:
	tipo = p_tipo
	definicion = p_definicion
	instancia = p_instancia
	clave = p_clave

func es(p_definicion: String) -> bool:
	return definicion == p_definicion

func _to_string() -> String:
	return "%s(%s)" % [instancia, definicion]

func serializar() -> Dictionary:
	return { "tipo": tipo, "definicion": definicion, "instancia": instancia, "clave": clave }

static func desde_dic(d: Dictionary) -> Identidad:
	return Identidad.new(
		str(d.get("tipo", "")), str(d.get("definicion", "")),
		str(d.get("instancia", "")), str(d.get("clave", "")))
