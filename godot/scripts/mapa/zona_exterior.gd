class_name ZonaExterior
extends Zona
## Adaptador de la isla jugable al contrato común de Zona.
##
## No duplica el terreno ni la transitabilidad: recibe las instancias que
## `Mundo` ya construyó. Así interiores, islas remotas y el exterior pueden
## compartir recepción de actores, límites y futura carga por zonas.

var isla_id: String = "isla_principal"

func montar(p_id: String, p_transitable: Transitable, p_actores: Node2D) -> void:
	isla_id = p_id
	id = p_id
	transitable = p_transitable
	actores = p_actores

func entrada() -> Vector2:
	return Vector2(transitable.limites().size) * 0.5 + Vector2(0.5, 0.5)
