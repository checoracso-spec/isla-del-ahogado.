class_name PruebaPersistenciaDatos
extends RefCounted
## Lo que el proceso A escribe y el proceso B espera encontrar.
##
## En un solo sitio a propósito: si estuviera duplicado en los dos scripts,
## bastaría cambiar un número en uno para que la prueba dejara de comprobar
## nada sin que se notara.

const RANURA := 98

const ORO := 1234
const SALUD := 77.0
const ENERGIA := 44.0
const DIA := 13
const HORA := 18.5
const RON_EN_MOCHILA := 3
const ZONA_INTERIOR := "interior_capitania_pa"

## Casilla concreta del interior donde se coloca el jugador antes de guardar.
## Elegida a mano para que esté libre de muebles en `interior_casa_a`.
const POS_INTERIOR := Vector2(2.5, 2.5)
