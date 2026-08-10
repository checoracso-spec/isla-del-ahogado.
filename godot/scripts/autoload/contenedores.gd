extends Node
## AUTOLOAD: Contenedores
##
## Dónde vive lo que hay dentro de un cofre, un barril o la bodega de un barco.
##
## POR QUÉ NO LO GUARDA EL PROPIO COFRE, que es la decisión importante:
## el nodo del cofre se destruye al salir del interior, y se vuelve a crear al
## entrar. Si el contenido viviera en el nodo, se perdería al salir y volvería
## a aparecer entero al entrar: ron infinito.
##
## Aquí el contenido está indexado por `instance_id`, sobrevive a que el nodo
## nazca y muera cien veces, y se guarda en la partida como datos planos.
##
## LA REGLA DEL CONTENIDO INICIAL: sólo se siembra la PRIMERA vez que se ve un
## instance_id. Si ya existe —porque ya lo abriste, o porque viene de una
## partida cargada— se devuelve tal cual esté, aunque esté vacío.

signal contenido_cambiado(instancia: String)

var _inventarios: Dictionary = {}      ## instancia_id -> Inventario
var _meta: Dictionary = {}             ## instancia_id -> { definicion, zona }

func _ready() -> void:
	Guardado.registrar("contenedores", _serializar, _cargar)

## La única vía de acceso. Siembra `contenido_inicial` sólo si es la primera vez.
func inventario_de(identidad: Identidad, contenido_inicial: Dictionary = {},
		zona: String = "") -> Inventario:
	if identidad == null:
		return null
	var id := identidad.instancia
	if _inventarios.has(id):
		return _inventarios[id]

	var inv := Inventario.new()
	for item_id in contenido_inicial:
		inv.anadir(str(item_id), int(contenido_inicial[item_id]))
	inv.cambiado.connect(func(_i, _n): contenido_cambiado.emit(id))
	_inventarios[id] = inv
	_meta[id] = { "definicion": identidad.definicion, "zona": zona }
	return inv

func existe(instancia: String) -> bool:
	return _inventarios.has(instancia)

func inventario(instancia: String) -> Inventario:
	return _inventarios.get(instancia)

func total() -> int:
	return _inventarios.size()

## Sólo para pruebas.
func reiniciar() -> void:
	_inventarios.clear()
	_meta.clear()

# ---------------------------------------------------------------------------
# GUARDADO
# ---------------------------------------------------------------------------

func _serializar() -> Dictionary:
	var lista := []
	for id in _inventarios:
		var m: Dictionary = _meta.get(id, {})
		lista.append({
			"instancia": id,
			"definicion": str(m.get("definicion", "")),
			"zona": str(m.get("zona", "")),
			"inventario": (_inventarios[id] as Inventario).serializar(),
		})
	return { "contenedores": lista }

func _cargar(d: Dictionary) -> void:
	# Se REEMPLAZA, no se mezcla: si al arrancar el mundo se creó un cofre con
	# ron y la partida lo tenía vacío, tiene que quedar vacío.
	_inventarios.clear()
	_meta.clear()
	for crudo in d.get("contenedores", []):
		var c: Dictionary = crudo
		var id := str(c.get("instancia", ""))
		if id == "":
			continue
		var inv := Inventario.new()
		inv.cargar(c.get("inventario", {}) as Dictionary)
		inv.cambiado.connect(func(_i, _n): contenido_cambiado.emit(id))
		_inventarios[id] = inv
		_meta[id] = { "definicion": str(c.get("definicion", "")), "zona": str(c.get("zona", "")) }
