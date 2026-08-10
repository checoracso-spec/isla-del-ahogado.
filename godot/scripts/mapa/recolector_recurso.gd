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
var intervalo_horas: float = 6.0
var activo: bool = true
var proxima_recoleccion: float = 0.0

func montar(p_fuente_instancia: String, p_edificio_id: String,
		p_trabajadores: int = 1, p_intervalo_horas: float = 6.0) -> void:
	fuente_instancia = p_fuente_instancia
	edificio_id = p_edificio_id
	trabajadores = maxi(1, p_trabajadores)
	intervalo_horas = maxf(0.1, p_intervalo_horas)
	proxima_recoleccion = _hora_total() + intervalo_horas

func _process(_delta: float) -> void:
	if not activo or Reloj.pausado or fuente_instancia == "":
		return
	var ahora := _hora_total()
	if ahora < proxima_recoleccion:
		return
	var resultado := RecursosMundo.recolectar_en_almacen(
		fuente_instancia, trabajadores, edificio_id)
	if int(resultado.get("ciclos", 0)) > 0:
		lote_recolectado.emit(self, resultado.get("productos", {}))
		proxima_recoleccion = ahora + intervalo_horas
	else:
		# Reintenta pronto si el almacén estaba lleno o la fuente agotada.
		proxima_recoleccion = ahora + 1.0

func ejecutar_ahora() -> Dictionary:
	if not activo or fuente_instancia == "":
		return {"ciclos": 0, "productos": {}}
	var resultado := RecursosMundo.recolectar_en_almacen(
		fuente_instancia, trabajadores, edificio_id)
	if int(resultado.get("ciclos", 0)) > 0:
		proxima_recoleccion = _hora_total() + intervalo_horas
		lote_recolectado.emit(self, resultado.get("productos", {}))
	return resultado

func _hora_total() -> float:
	return float(Reloj.dia * 24) + Reloj.hora
