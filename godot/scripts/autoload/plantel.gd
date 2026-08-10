extends Node
## AUTOLOAD: Plantel
##
## Quién está reclutado y dónde está asignado. Su trabajo real es responder
## una pregunta que le hace el resto del juego cien veces por partida:
##   "¿cuánto me modifica X el personal que tengo?"
##
## Así, cuando escribes un personaje nuevo en BaseDeDatos, su habilidad
## funciona sola. No hay que tocar la herrería ni la taberna ni el puerto.

signal reclutado(id: String)
signal asignado(id_personaje: String, id_edificio: String)

## Lista viva de tipos de efecto que el juego consulta hoy.
## Si inventas un tipo nuevo, añádelo aquí para acordarte de leerlo en alguna parte.
const TIPOS_CONOCIDOS := [
	"velocidad_produccion", "capacidad_carga", "tiempo_expedicion",
	"consumo_ron", "consumo_raciones", "precio_venta", "barcos_simultaneos",
	"robo_almacen", "rareza_playa", "rutas_reveladas", "defensa",
	"experiencia_npc", "ingreso_oro", "merma_almacen", "rescate_automatico",
	"mercader_nocturno", "puntos_tecnologia_dia", "moral_global",
	"alerta_bloqueo", "riesgo_naufragio",
]

var reclutados: Array[String] = []
var asignaciones: Dictionary = {}    ## id_personaje -> id_edificio ("" = sin destino)

func reclutar(id_personaje: String) -> bool:
	if not BaseDeDatos.personajes.has(id_personaje):
		push_warning("No existe el personaje '%s'" % id_personaje)
		return false
	if id_personaje in reclutados:
		return false
	reclutados.append(id_personaje)
	asignaciones[id_personaje] = ""
	reclutado.emit(id_personaje)
	return true

func asignar(id_personaje: String, id_edificio: String) -> void:
	if id_personaje not in reclutados:
		return
	asignaciones[id_personaje] = id_edificio
	asignado.emit(id_personaje, id_edificio)

## Suma de todos los efectos de un tipo. "ambito" filtra por edificio:
##   Plantel.modificador("velocidad_produccion", "herreria")  -> 0.30 con Barbanegra dentro
## Un efecto con ambito "" cuenta siempre; uno con ambito concreto sólo si coincide
## Y además el personaje está asignado ahí.
func modificador(tipo: String, ambito: String = "") -> float:
	var total := 0.0
	for ef in _efectos_activos():
		if ef.get("tipo", "") != tipo:
			continue
		var ef_ambito: String = ef.get("ambito", "")
		if ef_ambito == "":
			total += float(ef.get("valor", 0.0))
		elif ef_ambito == ambito and ef.get("_asignado_en", "") == ef_ambito:
			total += float(ef.get("valor", 0.0))
	return total

## Igual que modificador() pero como multiplicador listo para usar: 1.0 + suma,
## nunca por debajo de 0.1 para que nada se quede congelado del todo.
func factor(tipo: String, ambito: String = "") -> float:
	return maxf(0.1, 1.0 + modificador(tipo, ambito))

## ¿Hay alguien que active una capacidad de sí/no? (Grace, Lafitte, Woodes...)
func tiene_capacidad(tipo: String) -> bool:
	return modificador(tipo) > 0.0

func quien_tiene(tipo: String) -> Array[String]:
	var res: Array[String] = []
	for id in reclutados:
		var p: PersonajeData = BaseDeDatos.personaje(id)
		if p == null:
			continue
		for ef in [p.efecto, p.efecto_extra]:
			if ef.get("tipo", "") == tipo:
				res.append(id)
	return res

func _efectos_activos() -> Array:
	var lista := []
	for id in reclutados:
		var p: PersonajeData = BaseDeDatos.personaje(id)
		if p == null:
			continue
		var destino: String = asignaciones.get(id, "")
		for ef in [p.efecto, p.efecto_extra]:
			if ef.is_empty():
				continue
			var copia: Dictionary = ef.duplicate()
			copia["_asignado_en"] = destino
			lista.append(copia)
	return lista

func descripcion_plantel() -> String:
	if reclutados.is_empty():
		return "Sin tripulación notable."
	var lineas := []
	for id in reclutados:
		var p: PersonajeData = BaseDeDatos.personaje(id)
		var destino: String = asignaciones.get(id, "")
		var donde := "sin destino"
		if destino != "":
			var e: EdificioData = BaseDeDatos.edificio(destino)
			donde = e.nombre if e != null else destino
		lineas.append("%s — %s (%s)" % [p.nombre, p.rol, donde])
	return "\n".join(lineas)
