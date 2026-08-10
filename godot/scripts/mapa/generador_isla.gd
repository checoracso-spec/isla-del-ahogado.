class_name GeneradorIsla
extends RefCounted
## Dibuja la isla: mar alrededor, playa, hierba y una explanada de piedra
## donde va el asentamiento.
##
## El terreno se guarda POR ESQUINAS, no por casillas. Una casilla mira sus
## cuatro esquinas y de ahí sale su rombo. Es lo que permite que la orilla no
## sea una escalera de píxeles.

const AGUA := ConstructorTileset.AGUA
const ARENA := ConstructorTileset.ARENA
const HIERBA := ConstructorTileset.HIERBA
const HIERBA_B := ConstructorTileset.HIERBA_B
const TIERRA := ConstructorTileset.TIERRA

var ancho: int
var alto: int
var esquinas: PackedInt32Array          ## (ancho+1) × (alto+1)
var _rnd := RandomNumberGenerator.new()

## Tres ruidos separados. Si se usa uno solo, los prados, el bosque y la
## explanada acaban calcados unos de otros y se nota.
var _ruido_hierba := FastNoiseLite.new()
var _ruido_bosque := FastNoiseLite.new()
var _ruido_plaza := FastNoiseLite.new()
var _radio_plaza := 0.0

## Casillas de la explanada, donde se puede construir y caminar.
var plaza: Array[Vector2i] = []
var centro_plaza := Vector2i.ZERO

func _init(p_ancho: int, p_alto: int, semilla: int = 20260808) -> void:
	ancho = p_ancho
	alto = p_alto
	_rnd.seed = semilla
	for par in [[_ruido_hierba, semilla + 1, 0.055], [_ruido_bosque, semilla + 2, 0.075],
			[_ruido_plaza, semilla + 3, 0.11]]:
		var r: FastNoiseLite = par[0]
		r.seed = int(par[1])
		r.frequency = float(par[2])
		r.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	esquinas = PackedInt32Array()
	esquinas.resize((ancho + 1) * (alto + 1))
	_generar()

func nivel(cx: int, cy: int) -> int:
	if cx < 0 or cy < 0 or cx > ancho or cy > alto:
		return AGUA
	return esquinas[cy * (ancho + 1) + cx]

func _poner(cx: int, cy: int, n: int) -> void:
	if cx < 0 or cy < 0 or cx > ancho or cy > alto:
		return
	esquinas[cy * (ancho + 1) + cx] = n

## Los cuatro niveles de una casilla, en orden arriba/derecha/abajo/izquierda.
func niveles_de(x: int, y: int) -> Array:
	return [nivel(x, y), nivel(x + 1, y), nivel(x + 1, y + 1), nivel(x, y + 1)]

func es_tierra(x: int, y: int) -> bool:
	for n in niveles_de(x, y):
		if int(n) <= ARENA:
			return false
	return true

func es_transitable(x: int, y: int) -> bool:
	# Se puede pisar la hierba y la arena; el agua no.
	for n in niveles_de(x, y):
		if int(n) == AGUA:
			return false
	return true

# ---------------------------------------------------------------------------

func _generar() -> void:
	var cx := ancho * 0.5
	var cy := alto * 0.5
	var radio := minf(ancho, alto) * 0.46

	# Ruido suave para que la costa no sea un círculo perfecto.
	var ruido := FastNoiseLite.new()
	ruido.seed = _rnd.randi()
	ruido.frequency = 0.045
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	for y in range(alto + 1):
		for x in range(ancho + 1):
			var d := Vector2(x - cx, y - cy).length()
			# La isla se alarga un poco en diagonal: en isométrico se ve mejor.
			var deforme := d + ruido.get_noise_2d(x, y) * radio * 0.30
			var n := AGUA
			if deforme < radio * 0.80:
				n = HIERBA
			elif deforme < radio:
				n = ARENA
			_poner(x, y, n)

	_forzar_arena_entre_hierba_y_agua()
	_abrir_ensenada()
	_forzar_arena_entre_hierba_y_agua()
	_marcar_plaza()

## Regla de oro del sistema de transiciones: hierba y agua nunca se tocan.
## Si una esquina de hierba tiene una vecina de agua, se convierte en arena.
func _forzar_arena_entre_hierba_y_agua() -> void:
	for _pasada in 3:
		var cambios := 0
		for y in range(alto + 1):
			for x in range(ancho + 1):
				if nivel(x, y) != HIERBA:
					continue
				var toca_agua := false
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
						Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					if nivel(x + d.x, y + d.y) == AGUA:
						toca_agua = true
						break
				if toca_agua:
					_poner(x, y, ARENA)
					cambios += 1
		if cambios == 0:
			return

## Una entrada de mar hasta el borde del pueblo: ahí van el muelle y el faro.
func _abrir_ensenada() -> void:
	var bx := int(ancho * 0.5)
	var by := int(alto * 0.5)
	var pasos := int(alto * 0.42)
	var x := bx + int(ancho * 0.30)
	var y := by + int(alto * 0.30)
	for i in pasos:
		var t := float(i) / pasos
		var radio := lerpf(4.5, 1.6, t)
		for dy in range(-6, 7):
			for dx in range(-6, 7):
				if Vector2(dx, dy).length() <= radio:
					_poner(x + dx, y + dy, AGUA)
		x -= 1
		y -= 1
		if i % 3 == 0:
			x += _rnd.randi_range(-1, 1)

## La explanada del pueblo: tierra pisoteada, con el borde comido por el ruido
## para que no parezca un círculo dibujado con compás.
func _marcar_plaza() -> void:
	centro_plaza = Vector2i(int(ancho * 0.42), int(alto * 0.42))
	_radio_plaza = minf(ancho, alto) * 0.24
	var r := int(_radio_plaza) + 3
	for y in range(centro_plaza.y - r, centro_plaza.y + r + 1):
		for x in range(centro_plaza.x - r, centro_plaza.x + r + 1):
			if x < 0 or y < 0 or x >= ancho or y >= alto:
				continue
			if es_explanada(x, y) and es_tierra(x, y):
				plaza.append(Vector2i(x, y))

## ¿Cae esta ESQUINA dentro de la explanada? Lo pregunta el pintor de tiles
## para elegir el rombo de transición hierba↔tierra.
func esquina_en_plaza(cx: int, cy: int) -> bool:
	var d := Vector2(cx - centro_plaza.x, cy - centro_plaza.y).length()
	return d + _ruido_plaza.get_noise_2d(cx, cy) * _radio_plaza * 0.45 < _radio_plaza

## Igual pero para el centro de una casilla (se usa al buscar solar).
func es_explanada(x: int, y: int) -> bool:
	var d := Vector2(x - centro_plaza.x, y - centro_plaza.y).length()
	return d + _ruido_plaza.get_noise_2d(x, y) * _radio_plaza * 0.45 < _radio_plaza

## Las cuatro esquinas de la casilla, como niveles HIERBA/TIERRA.
func niveles_plaza(x: int, y: int) -> Array:
	var res := []
	for e: Vector2i in Iso.esquinas(x, y):
		res.append(TIERRA if esquina_en_plaza(e.x, e.y) else HIERBA)
	return res

## Variante de hierba en manchas grandes, no tile a tile: si se sortea por
## casilla, el prado sale a cuadros escoceses.
func variante_hierba(x: int, y: int) -> int:
	return HIERBA_B if _ruido_hierba.get_noise_2d(x, y) > 0.18 else HIERBA

## Espesura del bosque: 0 despejado, 1 cerrado. Crece al alejarse del pueblo.
func espesura(x: int, y: int) -> float:
	var d := Vector2(x - centro_plaza.x, y - centro_plaza.y).length()
	var lejos := clampf((d - _radio_plaza - 4.0) / 18.0, 0.0, 1.0)
	var n := (_ruido_bosque.get_noise_2d(x, y) + 1.0) * 0.5
	return clampf(n * 1.5 - 0.45, 0.0, 1.0) * lejos

func hueco_libre(lado: int, ocupadas: Dictionary) -> Vector2i:
	## Busca un cuadrado de `lado` casillas de tierra que nadie esté usando.
	for _intento in 400:
		var p: Vector2i = plaza[_rnd.randi() % plaza.size()]
		if _cabe(p, lado, ocupadas):
			return p
	# plan B: barrer toda la isla
	for y in range(alto - lado):
		for x in range(ancho - lado):
			if _cabe(Vector2i(x, y), lado, ocupadas):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _cabe(p: Vector2i, lado: int, ocupadas: Dictionary) -> bool:
	for dy in range(-1, lado + 1):          # un tile de respeto alrededor
		for dx in range(-1, lado + 1):
			var t := Vector2i(p.x + dx, p.y + dy)
			if not es_tierra(t.x, t.y):
				return false
			if ocupadas.has(t):
				return false
	return true

func marcar_ocupado(p: Vector2i, lado: int, ocupadas: Dictionary, quien: String) -> void:
	for dy in lado:
		for dx in lado:
			ocupadas[Vector2i(p.x + dx, p.y + dy)] = quien
