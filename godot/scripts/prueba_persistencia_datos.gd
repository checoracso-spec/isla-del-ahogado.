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
const FUENTE_GUARDADA := "semillero_isla"
const CULTIVO_GUARDADO := "citricos"
const ETAPA_CULTIVO_GUARDADA := 3
const GRUA_ACTIVA := true
const RUTA_GLOBAL_GUARDADA := "principal_ceniza"
const DESTINO_GLOBAL_GUARDADO := "isla_ceniza"
const RANURA_ZONA_GLOBAL := 97
const ANIMAL_GUARDADO := "cerdo_salvaje"
const POS_ANIMAL := Vector2(3.5, 3.5)

## Casilla concreta del interior donde se coloca el jugador antes de guardar.
## Elegida a mano para que esté libre de muebles en `interior_casa_a`.
const POS_INTERIOR := Vector2(2.5, 2.5)
