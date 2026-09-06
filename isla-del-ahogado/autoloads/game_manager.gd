extends Node

## Estado general de la partida y referencia a la escena de mundo activa.
## Este esqueleto reserva el punto de coordinación para los sistemas futuros.

var world_scene: Node = null
var player: Node = null
var current_slot: int = 1
