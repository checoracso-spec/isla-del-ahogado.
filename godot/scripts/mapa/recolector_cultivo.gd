class_name RecolectorCultivo
extends Node

## Automatiza una parcela utilizando el estado central de CultivosMundo.
## Planta con semillas del Almacen y deposita la cosecha en ese mismo destino.

signal lote_procesado(recolector: RecolectorCultivo, accion: String, productos: Dictionary)

var parcela_instancia: String = ""
var edificio_id: String = ""
var trabajadores: int = 1
var horario_id: String = ""
var activo: bool = true
var usar_trabajadores_npc: bool = false
var intervalo_horas: float = 1.0
var proxima_accion: float = 0.0

func montar(p_parcela_instancia: String, p_edificio_id: String = "",
		p_trabajadores: int = 1, p_horario_id: String = "") -> void:
	parcela_instancia = p_parcela_instancia
	edificio_id = p_edificio_id
	trabajadores = maxi(0, p_trabajadores)
	horario_id = p_horario_id
	proxima_accion = 0.0

func _process(_delta: float) -> void:
	if not activo or Reloj.pausado or trabajadores_efectivos() <= 0 or parcela_instancia == "":
		return
	if not en_horario() or _hora_total() < proxima_accion:
		return
	ejecutar_ahora()

func en_horario() -> bool:
	if horario_id == "":
		return true
	var horario: HorarioData = BaseDeDatos.horario(horario_id)
	return horario != null and horario.estado_en(Reloj.hora, ["trabajar"]) == "abierta"

func ejecutar_ahora() -> Dictionary:
	if not activo or trabajadores_efectivos() <= 0 or parcela_instancia == "":
		return {"ok": false, "accion": "", "productos": {}}
	var etapa := CultivosMundo.etapa(parcela_instancia)
	if etapa == 0:
		if CultivosMundo.sembrar_en_almacen(parcela_instancia, edificio_id):
			proxima_accion = _hora_total() + intervalo_horas
			lote_procesado.emit(self, "sembrar", {})
			return {"ok": true, "accion": "sembrar", "productos": {}}
	elif etapa == 3:
		var resultado := CultivosMundo.cosechar_en_almacen(parcela_instancia, edificio_id)
		if bool(resultado.get("ok", false)):
			proxima_accion = _hora_total() + intervalo_horas
			lote_procesado.emit(self, "cosechar", resultado.get("productos", {}))
			return {"ok": true, "accion": "cosechar", "productos": resultado.get("productos", {})}
	proxima_accion = _hora_total() + intervalo_horas
	return {"ok": false, "accion": "esperar", "productos": {}}

func trabajadores_efectivos() -> int:
	if not usar_trabajadores_npc:
		return maxi(0, trabajadores)
	var gestor := get_node_or_null("/root/NpcsMundo")
	if gestor == null or not gestor.has_method("trabajadores_activos"):
		return maxi(0, trabajadores)
	return maxi(0, int(gestor.call("trabajadores_activos", edificio_id)))

func serializar() -> Dictionary:
	return {
		"parcela_instancia": parcela_instancia,
		"edificio_id": edificio_id,
		"trabajadores": trabajadores,
		"horario_id": horario_id,
		"activo": activo,
		"usar_trabajadores_npc": usar_trabajadores_npc,
		"intervalo_horas": intervalo_horas,
		"proxima_accion": proxima_accion,
	}

func cargar(datos: Dictionary) -> void:
	parcela_instancia = str(datos.get("parcela_instancia", parcela_instancia))
	edificio_id = str(datos.get("edificio_id", edificio_id))
	trabajadores = maxi(0, int(datos.get("trabajadores", trabajadores)))
	horario_id = str(datos.get("horario_id", horario_id))
	activo = bool(datos.get("activo", activo))
	usar_trabajadores_npc = bool(datos.get("usar_trabajadores_npc", usar_trabajadores_npc))
	intervalo_horas = maxf(0.1, float(datos.get("intervalo_horas", intervalo_horas)))
	proxima_accion = float(datos.get("proxima_accion", proxima_accion))

func _hora_total() -> float:
	return float(Reloj.dia * 24) + Reloj.hora
