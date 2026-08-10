class_name Interactuable
extends Node2D
## Algo del mundo con lo que se puede hacer "E".
##
## La regla: quien hereda de aquí decide QUÉ pasa; nunca decide cómo se
## detecta, ni cómo se dibuja el aviso, ni cómo cambia el juego de escenario.
## Así una puerta no necesita saber que existe un gestor de interiores: se
## limita a avisar de que la han cruzado.
##
## Hoy sólo lo usan las puertas. Después: cofres, NPCs, estaciones, camas,
## mesas, barcos y animales, sin tocar ni el jugador ni esta clase.

const GRUPO := "interactuables"

## A qué distancia (en casillas) se ofrece la acción.
@export var alcance: float = 1.4

## Casillas libres desde las que puede usarse el objeto. Si está vacío se
## conserva el comportamiento histórico: se usa la propia casilla.
var casillas_interaccion: Array[Vector2i] = []

func _ready() -> void:
	add_to_group(GRUPO)

## El texto que se enseña: "Entrar", "Abrir", "Hablar"...
func texto_accion() -> String:
	return "Usar"

## Permite desactivar temporalmente sin sacarlo del mundo (puerta cerrada con
## llave, cofre vacío, NPC dormido).
func disponible(_quien: Node) -> bool:
	return true

## Sobrescribir. Aquí va lo que hace el objeto.
func interactuar(_quien: Node) -> void:
	pass

## Dónde está, en casillas. Por defecto se deduce de la posición en pantalla.
func casilla() -> Vector2i:
	return Iso.a_tile(position)

func establecer_casillas_interaccion(puntos: Array) -> void:
	casillas_interaccion.clear()
	for punto in puntos:
		if punto is Vector2i and punto not in casillas_interaccion:
			casillas_interaccion.append(punto)

func puntos_interaccion() -> Array[Vector2i]:
	if not casillas_interaccion.is_empty():
		return casillas_interaccion
	return [casilla()]

func distancia_interaccion(pos_tile: Vector2) -> float:
	var distancia := INF
	for punto in puntos_interaccion():
		distancia = minf(distancia, pos_tile.distance_to(Vector2(punto) + Vector2(0.5, 0.5)))
	return distancia
