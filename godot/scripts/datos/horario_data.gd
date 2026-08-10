class_name HorarioData
extends Resource

## Rutina diaria data-driven. Cada tramo usa horas [desde, hasta) y una
## actividad legible por el actor: dormir, trabajar, comer, taberna o pasear.

@export var id: String = ""
@export var nombre: String = ""
@export var tramos: Array = []

static func desde_dic(d: Dictionary) -> HorarioData:
	var h := HorarioData.new()
	h.id = str(d.get("id", ""))
	h.nombre = str(d.get("nombre", h.id))
	h.tramos = d.get("tramos", []).duplicate(true)
	h.resource_name = h.nombre
	return h

func actividad_en(hora: float) -> String:
	for tramo in tramos:
		var desde := float(tramo.get("desde", 0.0))
		var hasta := float(tramo.get("hasta", 24.0))
		var dentro := hora >= desde and hora < hasta
		if desde > hasta:
			dentro = hora >= desde or hora < hasta
		if dentro:
			return str(tramo.get("actividad", "pasear"))
	return "pasear"

func estado_en(hora: float, productivas: Array, preparacion: Array = []) -> String:
	var actividad := actividad_en(hora)
	if actividad in productivas:
		return "abierta"
	if actividad in preparacion:
		return "preparando"
	return "detenida"
