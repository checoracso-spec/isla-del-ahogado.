class_name Capas
extends RefCounted
## En qué orden se dibuja el mundo, en un solo sitio.
##
## LA REGLA QUE NO SE PUEDE ROMPER:
##
##   Dentro del contenedor ordenado por profundidad NO se usa `z_index`.
##
## El orden ahí lo decide la Y del nodo, y `z_index` se la salta: un tejado con
## z_index alto se dibujaría encima de un actor que pasa POR DELANTE de la casa.
## El error es sutil porque casi siempre se ve bien, y sólo canta cuando alguien
## camina justo por delante.
##
## Para ordenar las piezas de una misma entidad —cuerpo, tejado, adornos— se usa
## el ORDEN DE HIJOS. Todas comparten la Y de su padre, así que viajan juntas
## como una sola unidad y nunca se cuelan en el bucket de otro.

# ---------------------------------------------------------------------------
# CAPAS GLOBALES — z_index de contenedores enteros, nunca de nodos sueltos
# ---------------------------------------------------------------------------

const TERRENO := -100            ## suelo base
const SUELO_DETALLE := -90       ## explanada, caminos, bosque
const MARCAS_SUELO := -80        ## felpudos, resaltados, sombras proyectadas
const MUNDO := 0                 ## ordenado por Y: edificios, objetos, actores
const EFECTOS := 60              ## clima y partículas que van sobre todo

# ---------------------------------------------------------------------------
# ORDEN DENTRO DE UNA ENTIDAD — posición entre los hijos, NO z_index
# ---------------------------------------------------------------------------

const HIJO_SOMBRA := 0
const HIJO_CUERPO := 1
const HIJO_TEJADO := 2
const HIJO_ADORNO := 3

## Capas de interfaz (CanvasLayer). Los avisos y carteles van AQUÍ, no en el
## mundo: un cartel no debe poder quedar tapado por una casa que está delante.
const CAPA_HUD := 100
const CAPA_DIALOGO := 110

## Cuelga `hijo` de `padre` en la posición que le toca según su orden.
## Añadir siempre por esta función evita que el orden dependa de en qué línea
## del código se creó cada pieza.
static func colocar(padre: Node, hijo: Node, orden: int) -> void:
	if hijo.get_parent() != padre:
		if hijo.get_parent() != null:
			hijo.get_parent().remove_child(hijo)
		padre.add_child(hijo)
	# Sin z_index: la posición entre hermanos es lo que decide.
	if hijo is CanvasItem:
		(hijo as CanvasItem).z_index = 0
	padre.move_child(hijo, mini(orden, padre.get_child_count() - 1))

## Comprueba que un nodo del mundo no se está saltando la ordenación por Y.
## La usa la prueba de capas.
static func respeta_orden_y(nodo: CanvasItem) -> bool:
	return nodo.z_index == 0
