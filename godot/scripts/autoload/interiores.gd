extends Node
## AUTOLOAD: Interiores  (el InteriorManager)
##
## Lleva el cambio de zona: apaga el exterior, levanta el interior, muda al
## jugador y devuelve la cámara a su sitio. Es el ÚNICO que hace esto; ni la
## puerta ni el jugador ni el mundo saben cómo se cambia de espacio.
##
## De momento el exterior no se descarga, sólo se apaga. Cuando la isla crezca
## y haya que liberar memoria, se cambia lo que hacen `_apagar_exterior` y
## `_encender_exterior` y nada más se entera: por eso están aisladas en dos
## funciones de tres líneas en vez de repartidas por el código.

signal entro(interior_id: String)
signal salio(edificio_instancia: String)
signal cofre_abierto(cofre: Cofre)

var activo: InteriorEscena = null
var _exterior: Node2D = null              ## el nodo Mundo
var _contenedor: Node2D = null            ## dónde se cuelgan los interiores
var _retorno := {}                        ## pos y dirección de fuera
var _interior_raiz_id: String = ""        ## planta conectada con la calle
var _edificio_definicion: String = ""
var _edificio_instancia: String = ""
var _casilla_exterior: Vector2i
var _puerta_instancia: String = ""

## Lo llama `mundo.gd` al arrancar.
func usar_exterior(mundo: Node2D, contenedor: Node2D) -> void:
	_exterior = mundo
	_contenedor = contenedor

func dentro() -> bool:
	return activo != null

# ---------------------------------------------------------------------------

## `pos_destino` sirve para reentrar tras cargar una partida en el sitio exacto
## donde se guardó, en vez de en la entrada.
func entrar(puerta: Puerta, jugador: Jugador,
		pos_destino: Vector2 = Vector2.INF) -> bool:
	if puerta == null or jugador == null or dentro():
		return false
	# Al restaurar una partida, la zona guardada puede ser una planta superior
	# del edificio. Una entrada manual siempre comienza por la planta raíz.
	var destino_id := puerta.interior_id
	if pos_destino != Vector2.INF \
			and Ubicacion.edificio_instancia == puerta.edificio_instancia \
			and Ubicacion.interior_id != "":
		destino_id = Ubicacion.interior_id
	var def: InteriorDefinicion = BaseDeDatos.interior(destino_id)
	if def == null:
		push_warning("No existe el interior '%s'" % puerta.interior_id)
		return false

	# Al salir se vuelve A LA PUERTA, no a donde estuviera el jugador cuando
	# entró. Parece un matiz y no lo es: al reentrar tras cargar una partida,
	# el jugador está en el punto de aparición por defecto —a media isla de la
	# casa— y salir lo teletransportaba allí.
	_retorno = {
		"pos": Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5),
		"direccion": jugador.direccion,
		"casilla_exterior": puerta.casilla_exterior,
		"zoom": _zoom_actual(),
	}
	_interior_raiz_id = puerta.interior_id
	_edificio_definicion = puerta.edificio_definicion
	_edificio_instancia = puerta.edificio_instancia
	_casilla_exterior = puerta.casilla_exterior
	_puerta_instancia = puerta.identidad.instancia if puerta.identidad != null else ""

	# El interior de ESTE edificio, no "el interior de las casas". Dos casas
	# iguales tienen dos interiores distintos, y por tanto dos cofres distintos.
	var identidad := _identidad_interior(def.id)

	activo = InteriorEscena.new()
	_contenedor.add_child(activo)
	activo.construir(def, puerta.casilla_exterior,
		puerta.edificio_definicion, puerta.edificio_instancia, identidad)
	Entidades.vincular(identidad, activo)
	_conectar_interior(activo, jugador)

	_apagar_exterior()
	var destino := activo.entrada() if pos_destino == Vector2.INF else pos_destino
	activo.recibir(jugador, destino)
	Ubicacion.entrar_en(def.id, puerta.edificio_instancia,
		_puerta_instancia,
		Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5), jugador.pos_tile)
	_zoom_interior()
	_ajustar_camara(activo.limites())
	entro.emit(def.id)
	return true

## Cambia de planta sin encender el exterior ni perder la ficha de retorno.
## La TransicionZona aporta sólo los datos; este gestor conserva la autoridad
## sobre nodos, jugador, ubicación y cámara.
func cambiar_zona(transicion: Interactuable, jugador: Jugador) -> bool:
	if not dentro() or transicion == null or jugador == null:
		return false
	var destino_id := str(transicion.get("destino_zona"))
	var def := BaseDeDatos.interior(destino_id)
	if def == null:
		return false

	var anterior := activo
	var siguiente := InteriorEscena.new()
	_contenedor.add_child(siguiente)
	var identidad := _identidad_interior(def.id)
	siguiente.construir(def, _casilla_exterior, _edificio_definicion,
		_edificio_instancia, identidad)
	Entidades.vincular(identidad, siguiente)
	_conectar_interior(siguiente, jugador)

	anterior.desactivar()
	activo = siguiente
	var entrada: Variant = transicion.get("entrada_destino")
	var casilla_entrada: Vector2i = entrada if entrada is Vector2i else Vector2i(1, 1)
	siguiente.recibir(jugador, Vector2(casilla_entrada) + Vector2(0.5, 0.5))
	if anterior.get_parent() != null:
		anterior.get_parent().remove_child(anterior)
	anterior.queue_free()

	var retorno_exterior: Vector2 = _retorno.get("pos", Ubicacion.retorno)
	Ubicacion.entrar_en(def.id, _edificio_instancia, _puerta_instancia,
		retorno_exterior, jugador.pos_tile)
	_ajustar_camara(siguiente.limites())
	entro.emit(def.id)
	return true

func salir(jugador: Jugador) -> bool:
	if not dentro() or jugador == null:
		return false
	var instancia := _edificio_instancia
	# Si se cargó una partida hecha dentro, `_retorno` está vacío porque nunca
	# se cruzó la puerta en esta sesión: entonces manda lo que diga Ubicacion.
	var destino: Vector2 = _retorno.get("pos", Ubicacion.retorno)
	var direccion: Vector2 = _retorno.get("direccion", Vector2(1, 1))
	# Se captura antes de limpiar `_retorno`. De otro modo la salida intentaba
	# restaurar el zoom cuando el dato ya no existía y conservaba el zoom 1×
	# del interior.
	var zoom_exterior: Vector2 = _retorno.get("zoom", _zoom_actual())

	_encender_exterior()
	# Se habla con el exterior por nombre de método y no con `as Mundo` a
	# propósito: `mundo.gd` ya depende de este autoload, y referenciar su clase
	# desde aquí cerraría el círculo.
	_exterior.call("recibir_jugador", jugador, destino)
	jugador.direccion = direccion

	# Se saca del árbol AHORA, no al final del fotograma. `queue_free` tarda, y
	# mientras tanto el interior viejo seguiría visible y su puerta seguiría
	# en el grupo de interactuables: si en ese hueco se entra en otro interior,
	# el jugador ve dos salidas y una de ellas está muerta.
	var saliente := activo
	activo = null
	if saliente.get_parent() != null:
		saliente.get_parent().remove_child(saliente)
	saliente.queue_free()
	_retorno.clear()
	_interior_raiz_id = ""
	_edificio_definicion = ""
	_edificio_instancia = ""
	_puerta_instancia = ""

	Ubicacion.volver_al_exterior(jugador.pos_tile)
	_restaurar_zoom_exterior(zoom_exterior)
	_ajustar_camara(_exterior.call("limites_exterior"))
	salio.emit(instancia)
	return true

func _al_pedir_salida(_puerta: Puerta, jugador: Jugador) -> void:
	salir(jugador)

func _al_pedir_transicion(transicion: Interactuable, quien: Node) -> void:
	var jugador := quien as Jugador
	if jugador != null:
		cambiar_zona(transicion, jugador)

func _conectar_interior(interior: InteriorEscena, jugador: Jugador) -> void:
	if interior.puerta_salida != null:
		interior.puerta_salida.atravesada.connect(_al_pedir_salida.bind(jugador))
	interior.cofre_abierto.connect(func(c: Cofre): cofre_abierto.emit(c))
	interior.transicion_solicitada.connect(_al_pedir_transicion)

## Mantiene la clave histórica de la planta baja para no cambiar los IDs de
## sus cofres. Las plantas adicionales incorporan su id y son independientes.
func _identidad_interior(interior_id: String) -> Identidad:
	var clave := "interior:%s" % _edificio_instancia
	if interior_id != _interior_raiz_id:
		clave += ":%s" % interior_id
	return Entidades.identificar("zona", interior_id, clave)

# ---------------------------------------------------------------------------

func _apagar_exterior() -> void:
	if _exterior != null and _exterior.has_method("mostrar_exterior"):
		_exterior.call("mostrar_exterior", false)

func _encender_exterior() -> void:
	if _exterior != null and _exterior.has_method("mostrar_exterior"):
		_exterior.call("mostrar_exterior", true)

func _ajustar_camara(limites: Rect2i) -> void:
	if _exterior == null or not _exterior.has_method("camara"):
		return
	var cam: CamaraIsla = _exterior.call("camara")
	if cam != null:
		cam.limitar_a_casillas(limites, 240.0)

func _camara() -> CamaraIsla:
	if _exterior == null or not _exterior.has_method("camara"):
		return null
	return _exterior.call("camara") as CamaraIsla

func _zoom_actual() -> Vector2:
	var cam := _camara()
	return cam.zoom if cam != null else Vector2.ONE

func _zoom_interior() -> void:
	var cam := _camara()
	if cam != null:
		cam.zoom_a_nivel(1)

func _restaurar_zoom_exterior(zoom_exterior: Vector2) -> void:
	var cam := _camara()
	if cam != null:
		cam.zoom = zoom_exterior
