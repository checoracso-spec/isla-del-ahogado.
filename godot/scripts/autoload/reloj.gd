extends Node
## AUTOLOAD: Reloj
##
## El pulso del juego. Todo lo demás (consumo de la taberna, avance de los
## barcos, plagas) se engancha a estas señales en vez de contar su propio tiempo.

signal hora_cambiada(hora: int)      ## una vez por hora de juego
signal nuevo_dia(dia: int)           ## al amanecer
signal anochecer(dia: int)           ## a las 20:00 — cuando abre la taberna

const DURACION_DIA_SEG := 240.0      ## un día completo = 4 minutos reales
const HORA_INICIAL := 7.5
const HORA_ANOCHECER := 20

var dia: int = 1
var hora: float = HORA_INICIAL
var pausado: bool = false
var velocidad: float = 1.0           ## 2.0 = el doble de rápido

var _ultima_hora_entera: int = -1

func _process(delta: float) -> void:
	if pausado:
		return
	hora += (24.0 / DURACION_DIA_SEG) * delta * velocidad
	if hora >= 24.0:
		hora -= 24.0
		dia += 1
		nuevo_dia.emit(dia)
	var h := int(hora)
	if h != _ultima_hora_entera:
		_ultima_hora_entera = h
		hora_cambiada.emit(h)
		if h == HORA_ANOCHECER:
			anochecer.emit(dia)

func texto() -> String:
	var h := int(hora)
	var m := int((hora - h) * 60.0)
	return "Día %d — %02d:%02d" % [dia, h, m]

func es_de_noche() -> bool:
	return hora >= 20.0 or hora < 6.0
