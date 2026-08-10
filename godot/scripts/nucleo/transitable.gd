class_name Transitable
extends RefCounted
## "¿Puedo pisar esta casilla?" — y nada más.
##
## Existe para que el jugador, los NPCs y los animales compartan UNA sola idea
## de colisión, y para que esa idea funcione igual en la isla, dentro de una
## casa o en la cubierta de un barco. Quien quiera ser pisable implementa esto.
##
## No hay cuerpos físicos ni formas de colisión: en un juego de rejilla
## isométrica la casilla ya es la unidad natural, y consultarla es más barato
## y más predecible que un motor de físicas.

## Sobrescribir. Por defecto todo es pisable.
func puede_pisar(_casilla: Vector2i) -> bool:
	return true

## Sobrescribir. Rect2i vacío = sin límites conocidos.
## La cámara lo usa para no salirse del mapa.
func limites() -> Rect2i:
	return Rect2i()

## ¿Cabe aquí un actor con esta huella? Se recorren TODAS las casillas que
## pisa, no sólo sus esquinas: así un animal grande no puede colarse por una
## pared fina que le quede justo en medio.
func cabe_en(pos: Vector2, huella: Huella) -> bool:
	if huella == null:
		return puede_pisar(Vector2i(int(floor(pos.x)), int(floor(pos.y))))
	for t in huella.casillas_bajo(pos):
		if not puede_pisar(t):
			return false
	return true

## Busca la casilla pisable más cercana a una dada. Se usa al aparecer en un
## sitio que resultó estar ocupado (al cargar partida, al salir por una puerta
## que quedó tapada...). Devuelve la original si no encuentra nada.
func casilla_libre_cerca(origen: Vector2i, radio_busqueda: int = 6) -> Vector2i:
	if puede_pisar(origen):
		return origen
	for r in range(1, radio_busqueda + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var t := Vector2i(origen.x + dx, origen.y + dy)
				if puede_pisar(t):
					return t
	return origen
