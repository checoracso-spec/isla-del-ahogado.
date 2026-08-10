extends Node
## AUTOLOAD: Entidades
##
## El registro civil del mundo: reparte identificadores únicos y sabe quién es
## quién. Todo lo que tenga que sobrevivir a un guardado pasa por aquí.
##
## CÓMO SE ACUÑA UN ID, que es la parte delicada:
##
## No son aleatorios. Cada entidad se pide con una CLAVE NATURAL —algo que la
## describe de forma estable, como "taberna@34,21"—. Si esa clave ya se vio
## antes, se devuelve el mismo id de siempre; si es nueva, se acuña el
## siguiente del contador.
##
## Con eso se cumplen las tres cosas que hacían falta:
##   · Regenerar el mundo con la misma semilla devuelve los MISMOS ids.
##   · Guardar y cargar los conserva, porque se guardan contador y claves.
##   · Nunca se reutiliza un id de algo que dejó de existir.

signal registrada(identidad: Identidad)
signal olvidada(instancia: String)

var _contador: int = 0
var _por_clave: Dictionary = {}      ## clave natural -> instancia_id
var _identidades: Dictionary = {}    ## instancia_id -> Identidad
var _vivas: Dictionary = {}          ## instancia_id -> Object (sólo lo que existe ahora)

func _ready() -> void:
	Guardado.registrar("entidades", _serializar, _cargar)

# ---------------------------------------------------------------------------
# ACUÑAR
# ---------------------------------------------------------------------------

## La vía normal. `clave` debe describir la entidad de forma estable: para un
## edificio, su definición y su casilla; para el jugador, "jugador".
func identificar(tipo: String, definicion: String, clave: String) -> Identidad:
	if _por_clave.has(clave):
		var existente: Identidad = _identidades[_por_clave[clave]]
		# La definición puede haber cambiado (se reconstruyó otra cosa en el
		# mismo sitio); la identidad se mantiene, el qué se actualiza.
		existente.definicion = definicion
		return existente

	_contador += 1
	var id := "%s_%04d" % [tipo, _contador]
	var identidad := Identidad.new(tipo, definicion, id, clave)
	_identidades[id] = identidad
	_por_clave[clave] = id
	return identidad

## Para cosas sin clave natural evidente (un objeto soltado en el suelo, un
## barco recién construido). Aquí el id sí depende del orden de creación, así
## que sólo debe usarse con cosas que se guarden explícitamente.
func identificar_nueva(tipo: String, definicion: String) -> Identidad:
	_contador += 1
	var id := "%s_%04d" % [tipo, _contador]
	var identidad := Identidad.new(tipo, definicion, id, id)
	_identidades[id] = identidad
	_por_clave[id] = id
	return identidad

## Clave natural de algo anclado a una casilla.
static func clave_en(definicion: String, casilla: Vector2i, zona: String = "isla") -> String:
	return "%s:%s@%d,%d" % [zona, definicion, casilla.x, casilla.y]

# ---------------------------------------------------------------------------
# QUIÉN ESTÁ VIVO AHORA
# ---------------------------------------------------------------------------

## Ata una identidad al objeto que la encarna en esta sesión. El objeto NO se
## guarda en la partida: sólo la identidad. Si es un nodo, se desapunta solo
## al salir del árbol.
func vincular(identidad: Identidad, objeto: Object) -> void:
	if identidad == null or objeto == null:
		return
	_vivas[identidad.instancia] = objeto
	if objeto is Node:
		var n := objeto as Node
		if not n.tree_exiting.is_connected(_al_salir):
			n.tree_exiting.connect(_al_salir.bind(identidad.instancia))
	registrada.emit(identidad)

func _al_salir(instancia: String) -> void:
	_vivas.erase(instancia)
	olvidada.emit(instancia)

func objeto(instancia: String) -> Object:
	var o: Object = _vivas.get(instancia)
	if o != null and o is Node and not is_instance_valid(o):
		_vivas.erase(instancia)
		return null
	return o

func identidad(instancia: String) -> Identidad:
	return _identidades.get(instancia)

func existe(instancia: String) -> bool:
	return _identidades.has(instancia)

## Todas las identidades conocidas de un tipo, existan ahora o no.
func de_tipo(tipo: String) -> Array:
	var res := []
	for id in _identidades:
		var i: Identidad = _identidades[id]
		if i.tipo == tipo:
			res.append(i)
	return res

## Sólo las que están encarnadas ahora mismo.
func vivas_de_tipo(tipo: String) -> Array:
	var res := []
	for id in _vivas:
		var i: Identidad = _identidades.get(id)
		if i != null and i.tipo == tipo:
			res.append(i)
	return res

func total() -> int:
	return _identidades.size()

## Sólo para pruebas: deja el registro como recién arrancado.
func reiniciar() -> void:
	_contador = 0
	_por_clave.clear()
	_identidades.clear()
	_vivas.clear()

# ---------------------------------------------------------------------------
# GUARDADO
# ---------------------------------------------------------------------------

func _serializar() -> Dictionary:
	var lista := []
	for id in _identidades:
		lista.append((_identidades[id] as Identidad).serializar())
	return { "contador": _contador, "identidades": lista }

func _cargar(d: Dictionary) -> void:
	_contador = int(d.get("contador", 0))
	_identidades.clear()
	_por_clave.clear()
	# Los objetos vivos NO se tocan: el mundo ya está montado y sus nodos
	# siguen siendo válidos. Sólo se restaura el papeleo.
	for cruda in d.get("identidades", []):
		var i := Identidad.desde_dic(cruda as Dictionary)
		if i.instancia == "":
			continue
		_identidades[i.instancia] = i
		if i.clave != "":
			_por_clave[i.clave] = i.instancia
