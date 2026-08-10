extends Node
## AUTOLOAD: Guardado  (el SaveManager)
##
## No sabe nada del juego. Es un listín: cada sistema se apunta con un nombre
## de sección y dos funciones —una que devuelve un diccionario y otra que lo
## recibe— y este nodo se encarga de escribirlo y leerlo.
##
## Por qué así: añadir "los NPCs también se guardan" será UNA llamada a
## `registrar` desde el sistema de NPCs, sin tocar este archivo ni los demás.
## Es la diferencia entre poder guardar el juego dentro de un año o tener que
## reescribirlo entero.
##
## Compatibilidad: al cargar, una sección que ya no existe se ignora, y una
## que falta se salta. Así una partida vieja no revienta con el juego nuevo.

signal guardado_hecho(ranura: int)
signal partida_cargada(ranura: int)
signal fallo(mensaje: String)

const VERSION := 1
const CARPETA := "user://partidas"

## Secciones previstas. Las que están a false todavía no las escribe nadie:
## están aquí para que se vea el hueco y nadie invente un nombre distinto.
const SECCIONES := {
	"reloj": true,
	"jugador": true,
	"mundo": true,
	"entidades": true,
	"contenedores": true,
	"crafting": true,
	"rastreo_carga": true,
	"mercado": true,
	"taberna": true,
	"recursos_mundo": true,
	"cultivos": true,
	"mapa_global": true,
	"npcs": false,
	"animales": false,
	"edificios": false,
	"barcos": false,
	"economia": false,
	"misiones": false,
	"eventos": false,
}

## Verdadero mientras se está guardando o cargando. Evita la reentrada: que la
## señal `partida_cargada` acabe provocando otra carga a medio camino.
## El antirrebote del teclado (F9 machacado) vive en quien lee el teclado.
var ocupado: bool = false

var _fuentes: Dictionary = {}          ## seccion -> { guardar: Callable, cargar: Callable }

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(CARPETA)
	# El reloj no se toca desde fuera, así que su sección la lleva este nodo.
	registrar("reloj",
		func() -> Dictionary: return { "dia": Reloj.dia, "hora": Reloj.hora },
		func(d: Dictionary) -> void:
			Reloj.dia = int(d.get("dia", 1))
			Reloj.hora = float(d.get("hora", Reloj.HORA_INICIAL)))

## Un sistema se apunta para ser guardado.
func registrar(seccion: String, al_guardar: Callable, al_cargar: Callable) -> void:
	if not SECCIONES.has(seccion):
		push_warning("Guardado: sección no prevista '%s'. Añádela a SECCIONES." % seccion)
	_fuentes[seccion] = { "guardar": al_guardar, "cargar": al_cargar }

func olvidar(seccion: String) -> void:
	_fuentes.erase(seccion)

func secciones_activas() -> Array:
	var l := _fuentes.keys()
	l.sort()
	return l

# ---------------------------------------------------------------------------

func ruta(ranura: int) -> String:
	return "%s/partida_%d.json" % [CARPETA, ranura]

func existe(ranura: int) -> bool:
	return FileAccess.file_exists(ruta(ranura))

func guardar(ranura: int = 1) -> bool:
	if ocupado:
		fallo.emit("Espera: hay una operación de guardado en curso")
		return false
	ocupado = true
	var resultado := _guardar_ahora(ranura)
	ocupado = false
	return resultado

func _guardar_ahora(ranura: int) -> bool:
	var datos := {
		"version": VERSION,
		"sellado": Time.get_datetime_string_from_system(),
		"secciones": {},
	}
	for seccion in _fuentes:
		var cb: Callable = _fuentes[seccion]["guardar"]
		datos["secciones"][seccion] = cb.call()

	var f := FileAccess.open(ruta(ranura), FileAccess.WRITE)
	if f == null:
		fallo.emit("No se pudo escribir %s" % ruta(ranura))
		return false
	f.store_string(JSON.stringify(datos, "\t"))
	f.close()
	guardado_hecho.emit(ranura)
	return true

func cargar(ranura: int = 1) -> bool:
	if ocupado:
		fallo.emit("Espera: hay una carga en curso")
		return false
	ocupado = true
	var resultado := _cargar_ahora(ranura)
	ocupado = false
	return resultado

func _cargar_ahora(ranura: int) -> bool:
	if not existe(ranura):
		fallo.emit("No hay partida en la ranura %d" % ranura)
		return false
	var f := FileAccess.open(ruta(ranura), FileAccess.READ)
	if f == null:
		fallo.emit("No se pudo leer %s" % ruta(ranura))
		return false
	var crudo := f.get_as_text()
	f.close()

	var leido: Variant = JSON.parse_string(crudo)
	if typeof(leido) != TYPE_DICTIONARY:
		fallo.emit("La partida %d está corrupta" % ranura)
		return false
	var datos: Dictionary = leido
	var secciones: Dictionary = datos.get("secciones", {})

	for seccion in _fuentes:
		if not secciones.has(seccion):
			continue                       # partida vieja: esa sección aún no existía
		var cb: Callable = _fuentes[seccion]["cargar"]
		cb.call(secciones[seccion] as Dictionary)

	partida_cargada.emit(ranura)
	return true

func borrar(ranura: int) -> void:
	if existe(ranura):
		DirAccess.remove_absolute(ruta(ranura))
