class_name EstacionTrabajo
extends Node
## Un edificio produciendo. Se añade como nodo hijo del edificio en la escena,
## o se crea por código (así lo hace la escena de prueba).
##
## Ciclo: reserva insumos -> trabaja N segundos -> entrega productos.
## Si faltan insumos, pide la sustitución de emergencia; si tampoco, se para
## y avisa una sola vez, y reintenta cada segundo hasta que llegue material.

signal produjo(productos: Dictionary, calidad: float)
signal detenida(motivo: String)
signal reanudada()

@export var edificio_id: String = ""
@export var receta_id: String = ""
@export var trabajadores: int = 1
@export var activa: bool = true
@export var cuota_diaria: int = 0          ## 0 = sin tope; si no, para al llegar
@export var horario_id: String = ""        ## vacío = producción continua
@export var actividades_productivas: Array = ["trabajar"]
@export var actividades_preparacion: Array = []
@export var usar_trabajadores_npc: bool = false

var progreso: float = 0.0
var calidad_lote: float = 1.0
var producido_hoy: int = 0
var parada: bool = false
var ultimo_motivo: String = ""             ## qué faltaba la última vez que paró

var _reintento: float = 0.0
var _lote_en_curso: Dictionary = {}

func _ready() -> void:
	Reloj.nuevo_dia.connect(func(_d): producido_hoy = 0)
	# Registra sus insumos como críticos: aviso temprano antes de quedarse a cero.
	var r := _receta()
	if r != null:
		for id in r.insumos:
			Almacen.vigilar(edificio_id, id, int(r.insumos[id]) * 3)

func _receta() -> RecetaData:
	return BaseDeDatos.receta(receta_id)

## Velocidad real: escala con trabajadores, la habilidad del personaje asignado
## (Barbanegra en la herrería) y baja cuando la tripulación está descontenta.
func velocidad() -> float:
	var v := float(trabajadores_efectivos())
	v *= Plantel.factor("velocidad_produccion", edificio_id)
	v *= lerpf(1.0, 0.45, Motin.nivel / 100.0)
	return v

func trabajadores_efectivos() -> int:
	if not usar_trabajadores_npc:
		return maxi(0, trabajadores)
	var gestor := get_node_or_null("/root/NpcsMundo")
	if gestor == null or not gestor.has_method("trabajadores_activos"):
		return maxi(0, trabajadores)
	return maxi(0, int(gestor.call("trabajadores_activos", edificio_id)))

## Una estación sólo se detiene por horario si se le asignó uno. Esto permite
## migrar edificio por edificio sin cambiar el comportamiento de los demás.
func en_horario(hora: float = Reloj.hora) -> bool:
	if horario_id == "":
		return true
	var horario: HorarioData = BaseDeDatos.horario(horario_id)
	if horario == null:
		return false
	return horario.estado_en(hora, actividades_productivas, actividades_preparacion) == "abierta"

func estado_operativo(hora: float = Reloj.hora) -> String:
	if horario_id == "":
		return "abierta"
	var horario: HorarioData = BaseDeDatos.horario(horario_id)
	return horario.estado_en(hora, actividades_productivas, actividades_preparacion) if horario != null else "detenida"

func _process(delta: float) -> void:
	if not activa or Reloj.pausado:
		return
	if estado_operativo() != "abierta":
		return
	var r := _receta()
	if r == null or trabajadores_efectivos() <= 0:
		return
	if cuota_diaria > 0 and producido_hoy >= cuota_diaria:
		return

	if _lote_en_curso.is_empty():
		if _reintento > 0.0:
			_reintento -= delta
			return
		_intentar_arrancar(r)
		return

	progreso += delta * velocidad()
	if progreso >= r.segundos:
		_entregar(r)

func _intentar_arrancar(r: RecetaData) -> void:
	var res := Almacen.consumir(r.insumos, edificio_id, r.sustitutos)
	if not res["ok"]:
		if not parada:
			parada = true
			var que_falta := []
			for id in res["faltan"]:
				que_falta.append("%d× %s" % [res["faltan"][id], BaseDeDatos.nombre_item(id)])
			ultimo_motivo = "Falta " + ", ".join(que_falta)
			detenida.emit(ultimo_motivo)
		_reintento = 1.0
		return

	if parada:
		parada = false
		reanudada.emit()
	_lote_en_curso = res["gasto"]
	calidad_lote = float(res["calidad"])
	progreso = 0.0

func _entregar(r: RecetaData) -> void:
	var salida: Dictionary = {}
	for id in r.productos:
		# Un lote de calidad baja rinde menos. Nunca menos de 1 unidad.
		var n := maxi(1, int(round(int(r.productos[id]) * calidad_lote)))
		Almacen.anadir(id, n, edificio_id)
		salida[id] = n
	producido_hoy += 1
	progreso = 0.0
	_lote_en_curso.clear()
	produjo.emit(salida, calidad_lote)

func porcentaje() -> float:
	var r := _receta()
	if r == null or r.segundos <= 0.0:
		return 0.0
	return clampf(progreso / r.segundos, 0.0, 1.0)

func estado_texto() -> String:
	if not activa:
		return "apagada"
	if trabajadores_efectivos() <= 0:
		return "sin trabajadores"
	if not en_horario():
		return "fuera de horario"
	if parada:
		return "detenida"
	if estado_operativo() == "preparando":
		return "preparando"
	if estado_operativo() == "detenida":
		return "fuera de horario"
	if cuota_diaria > 0 and producido_hoy >= cuota_diaria:
		return "cuota cumplida"
	return "produciendo"
