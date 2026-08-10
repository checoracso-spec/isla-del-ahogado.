class_name RecolectorRecurso
extends Node
## Componente reutilizable para automatizar una fuente del mundo.
##
## No conoce edificios concretos ni crea inventarios paralelos. Sólo programa
## ciclos de RecursosMundo hacia Almacen; una futura grúa, red o estación de
## recolección puede montar este componente con sus propios datos.

signal lote_recolectado(recolector: RecolectorRecurso, productos: Dictionary)

var fuente_instancia: String = ""
var edificio_id: String = ""
var trabajadores: int = 1
## Cuando estÃ¡ activo, la capacidad de la estaciÃ³n la determina el plantel
## vivo del mundo. El valor estÃ¡tico sigue siendo el respaldo para zonas
## remotas y escenas de prueba sin NPCs.
var usar_trabajadores_npc: bool = false
var horario_id: String = ""
var intervalo_horas: float = 6.0
var activo: bool = true
var proxima_recoleccion: float = 0.0

func montar(p_fuente_instancia: String, p_edificio_id: String,
		p_trabajadores: int = 1, p_intervalo_horas: float = 6.0,
		p_horario_id: String = "") -> void:
	fuente_instancia = p_fuente_instancia
	edificio_id = p_edificio_id
	trabajadores = maxi(1, p_trabajadores)
	intervalo_horas = maxf(0.1, p_intervalo_horas)
	horario_id = p_horario_id
	proxima_recoleccion = _hora_total() + intervalo_horas

func en_horario(hora: float = Reloj.hora) -> bool:
	if horario_id == "":
		return true
	var horario: HorarioData = BaseDeDatos.horario(horario_id)
	return horario != null and horario.estado_en(hora, ["trabajar"]) == "abierta"

func trabajadores_efectivos() -> int:
	if not usar_trabajadores_npc:
		return trabajadores
	var plantel := get_node_or_null("/root/NpcsMundo")
	if plantel == null or not plantel.has_method("trabajadores_activos"):
		return trabajadores
	return maxi(0, int(plantel.call("trabajadores_activos", edificio_id)))

func _process(_delta: float) -> void:
	if not activo or Reloj.pausado or fuente_instancia == "" or not en_horario():
		return
	var ahora := _hora_total()
	if ahora < proxima_recoleccion:
		return
	var resultado := RecursosMundo.recolectar_en_almacen(
		fuente_instancia, trabajadores_efectivos(), edificio_id)
	if int(resultado.get("ciclos", 0)) > 0:
		lote_recolectado.emit(self, resultado.get("productos", {}))
		proxima_recoleccion = ahora + intervalo_horas
	else:
		# Reintenta pronto si el almacén estaba lleno o la fuente agotada.
		proxima_recoleccion = ahora + 1.0

func ejecutar_ahora() -> Dictionary:
	if not activo or fuente_instancia == "" or not en_horario():
		return {"ciclos": 0, "productos": {}}
	var resultado := RecursosMundo.recolectar_en_almacen(
		fuente_instancia, trabajadores_efectivos(), edificio_id)
	if int(resultado.get("ciclos", 0)) > 0:
		proxima_recoleccion = _hora_total() + intervalo_horas
		lote_recolectado.emit(self, resultado.get("productos", {}))
	return resultado

func serializar() -> Dictionary:
	return {
		"fuente_instancia": fuente_instancia,
		"edificio_id": edificio_id,
		"trabajadores": trabajadores,
		"usar_trabajadores_npc": usar_trabajadores_npc,
		"horario_id": horario_id,
		"intervalo_horas": intervalo_horas,
		"activo": activo,
		"proxima_recoleccion": proxima_recoleccion,
	}

func cargar(datos: Dictionary) -> void:
	fuente_instancia = str(datos.get("fuente_instancia", fuente_instancia))
	edificio_id = str(datos.get("edificio_id", edificio_id))
	trabajadores = maxi(1, int(datos.get("trabajadores", trabajadores)))
	usar_trabajadores_npc = bool(datos.get("usar_trabajadores_npc", usar_trabajadores_npc))
	horario_id = str(datos.get("horario_id", horario_id))
	intervalo_horas = maxf(0.1, float(datos.get("intervalo_horas", intervalo_horas)))
	activo = bool(datos.get("activo", activo))
	proxima_recoleccion = float(datos.get("proxima_recoleccion", _hora_total() + intervalo_horas))

func _hora_total() -> float:
	return float(Reloj.dia * 24) + Reloj.hora
