extends Control
## Panel de mando de prueba. NO es la interfaz final del juego: es el banco de
## pruebas para ver que la logística funciona antes de dibujar nada.
##
## Al arrancar monta una guarida mínima (taberna, herrería, muelle), recluta
## cuatro corsarios y deja correr el tiempo. Los botones de abajo provocan a
## propósito las situaciones interesantes: cortar el acero, mandar un barco,
## saltarse la cena.

const COLOR_FONDO := Color("13161c")
const COLOR_PANEL := Color("1c212b")
const COLOR_TEXTO := Color("d9dde6")
const COLOR_TENUE := Color("7d8798")
const COLOR_ORO := Color("d4a017")

var estaciones: Array[EstacionTrabajo] = []
var registro: Array[String] = []

@onready var _fondo := ColorRect.new()
var _lbl_reloj: Label
var _barra_motin: ProgressBar
var _lbl_motin: Label
var _lbl_almacen: RichTextLabel
var _lbl_estaciones: RichTextLabel
var _lbl_flota: RichTextLabel
var _lbl_registro: RichTextLabel

func _ready() -> void:
	_montar_ui()
	_montar_guarida()
	_conectar_senales()
	_apuntar("Guarida en marcha. El tiempo corre: 1 día = 4 minutos.")

# ---------------------------------------------------------------------------
# LA GUARIDA DE PRUEBA
# ---------------------------------------------------------------------------

func _montar_guarida() -> void:
	# Despensa inicial: da para unos días, no para siempre.
	for par in [["ron", 30], ["raciones", 40], ["doblon", 900], ["madera_naufragio", 60],
			["polvora_humeda", 25], ["carbon", 30], ["acero_imperial", 12],
			["aceite_imperial", 4], ["grasa_ballena", 30], ["azufre_volcanico", 18],
			["seda_robada", 6], ["cuero", 10]]:
		Almacen.anadir(par[0], par[1], "inicio")

	# Cuatro corsarios, cada uno donde su habilidad se nota.
	for id in ["calico_jack", "barbanegra", "anne_bonny", "dientes_oro"]:
		Plantel.reclutar(id)
	Plantel.asignar("calico_jack", "taberna")
	Plantel.asignar("barbanegra", "herreria")
	Plantel.asignar("anne_bonny", "capitania")

	_abrir("taberna", "servicio_taberna", 3)
	_abrir("herreria", "forjar_canon", 4)
	_abrir("herreria", "secar_polvora", 2)
	_abrir("muelle_grua", "rastrillar_marea", 3)
	_abrir("muelle_grua", "curar_madera", 2)
	_abrir("corrales", "salar_carne", 1)

func _abrir(edificio: String, receta: String, gente: int) -> EstacionTrabajo:
	var e := EstacionTrabajo.new()
	e.edificio_id = edificio
	e.receta_id = receta
	e.trabajadores = gente
	e.name = "%s_%s" % [edificio, receta]
	add_child(e)
	estaciones.append(e)
	e.detenida.connect(_al_pararse.bind(edificio))
	e.reanudada.connect(_al_reanudar.bind(edificio))
	e.produjo.connect(_al_producir.bind(edificio))
	return e

func _al_pararse(motivo: String, edificio: String) -> void:
	_apuntar("[color=#e07b39]⚠ %s parada — %s[/color]" % [_nombre(edificio), motivo])

func _al_reanudar(edificio: String) -> void:
	_apuntar("[color=#4caf50]✔ %s reanuda la producción.[/color]" % _nombre(edificio))

func _al_producir(productos: Dictionary, calidad: float, edificio: String) -> void:
	if calidad >= 0.99:
		return                                  # los lotes normales no ensucian la bitácora
	var partes := []
	for id in productos:
		partes.append("%d× %s" % [productos[id], BaseDeDatos.nombre_item(id)])
	_apuntar("[color=#d4a017]%s: %s (calidad %d%%)[/color]"
		% [_nombre(edificio), ", ".join(partes), int(calidad * 100)])

func _conectar_senales() -> void:
	Almacen.cuello_de_botella.connect(_al_cuello)
	Almacen.cuello_resuelto.connect(_al_resolverse)
	Almacen.sustitucion_aplicada.connect(_al_sustituir)
	Almacen.robo.connect(_al_robo)

	Motin.carencia.connect(_al_faltar)
	Motin.umbral_cruzado.connect(_al_umbral)
	Motin.incidente.connect(_al_incidente)

	Reloj.nuevo_dia.connect(_al_amanecer)

	RastreoCarga.cargamento_zarpo.connect(_al_zarpar)
	RastreoCarga.informe_interceptacion.connect(_al_interceptar)
	RastreoCarga.cargamento_atracado.connect(_al_atracar)
	RastreoCarga.cargamento_perdido.connect(_al_perder)
	RastreoCarga.carga_descargada.connect(_al_descargar)

func _al_cuello(est: String, insumo: String, faltan: int) -> void:
	_apuntar("[color=#c0392b]CUELLO DE BOTELLA — %s necesita %d× %s[/color]"
		% [_nombre(est), faltan, BaseDeDatos.nombre_item(insumo)])

func _al_resolverse(est: String, insumo: String) -> void:
	_apuntar("[color=#4caf50]Resuelto: %s ya tiene %s[/color]"
		% [_nombre(est), BaseDeDatos.nombre_item(insumo)])

func _al_sustituir(est: String, orig: String, sust: String, n: int) -> void:
	_apuntar("[color=#5b9bd5]PLAN B en %s: %d× %s en lugar de %s[/color]"
		% [_nombre(est), n, BaseDeDatos.nombre_item(sust), BaseDeDatos.nombre_item(orig)])

func _al_robo(quien: String, id: String, n: int) -> void:
	_apuntar("[color=#c0392b]%s se llevó %d× %s[/color]" % [quien, n, BaseDeDatos.nombre_item(id)])

func _al_faltar(id: String, faltaban: int) -> void:
	_apuntar("[color=#c0392b]La tripulación no cobró/comió: faltan %d× %s[/color]"
		% [faltaban, BaseDeDatos.nombre_item(id)])

func _al_umbral(nombre: String, n: float) -> void:
	_apuntar("[b]MOTÍN: %s (%d)[/b]" % [nombre.to_upper(), int(n)])

func _al_incidente(tipo: String, detalle: String) -> void:
	_apuntar("[color=#c0392b][%s] %s[/color]" % [tipo, detalle])

func _al_amanecer(d: int) -> void:
	_apuntar("[b]— Amanece el día %d —[/b]" % d)

func _al_zarpar(m: Dictionary) -> void:
	_apuntar("Zarpa la %s hacia %s (%d días)."
		% [RastreoCarga.BARCOS[m["barco"]]["nombre"], m["destino"], m["dias_total"]])

func _al_interceptar(m: Dictionary) -> void:
	_apuntar("[color=#e07b39]INFORME: la Marina alcanza a %s. Decide con los botones de abajo.[/color]" % m["id"])

func _al_atracar(m: Dictionary) -> void:
	_apuntar("[color=#4caf50]%s atraca. Carga esperando en el puerto.[/color]" % m["id"])

func _al_perder(m: Dictionary, motivo: String) -> void:
	_apuntar("[color=#c0392b]%s perdido: %s[/color]" % [m["id"], motivo])

func _al_descargar(m: Dictionary) -> void:
	_apuntar("Descargado %s en los cofres." % m["id"])

# ---------------------------------------------------------------------------
# INTERFAZ
# ---------------------------------------------------------------------------

func _montar_ui() -> void:
	_fondo.color = COLOR_FONDO
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fondo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 8)
	raiz.offset_left = 16
	raiz.offset_top = 12
	raiz.offset_right = -16
	raiz.offset_bottom = -12
	add_child(raiz)

	# --- cabecera: reloj + motín ---
	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 20)
	raiz.add_child(cabecera)

	_lbl_reloj = Label.new()
	_lbl_reloj.add_theme_font_size_override("font_size", 20)
	_lbl_reloj.add_theme_color_override("font_color", COLOR_ORO)
	_lbl_reloj.custom_minimum_size.x = 200
	cabecera.add_child(_lbl_reloj)

	var caja_motin := VBoxContainer.new()
	caja_motin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(caja_motin)

	_lbl_motin = Label.new()
	_lbl_motin.add_theme_color_override("font_color", COLOR_TEXTO)
	caja_motin.add_child(_lbl_motin)

	_barra_motin = ProgressBar.new()
	_barra_motin.max_value = 100.0
	_barra_motin.show_percentage = false
	_barra_motin.custom_minimum_size.y = 18
	caja_motin.add_child(_barra_motin)

	# --- tres columnas ---
	var columnas := HBoxContainer.new()
	columnas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.add_theme_constant_override("separation", 10)
	raiz.add_child(columnas)

	_lbl_almacen = _columna(columnas, "COFRES / PUERTO / MAR", 1.0)
	_lbl_estaciones = _columna(columnas, "ESTACIONES", 1.1)
	_lbl_flota = _columna(columnas, "FLOTA", 0.9)

	# --- registro ---
	var caja_reg := _panel()
	caja_reg.custom_minimum_size.y = 190
	raiz.add_child(caja_reg)
	var vreg := _interior(caja_reg)
	vreg.add_child(_titulo("BITÁCORA"))
	_lbl_registro = RichTextLabel.new()
	_lbl_registro.bbcode_enabled = true
	_lbl_registro.scroll_following = true
	_lbl_registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lbl_registro.add_theme_color_override("default_color", COLOR_TEXTO)
	vreg.add_child(_lbl_registro)

	# --- botones ---
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 6)
	raiz.add_child(botones)
	_boton(botones, "Cortar el acero", _bloqueo_naval)
	_boton(botones, "Vaciar el ron", func(): Almacen.mermar("ron", Almacen.cantidad("ron"), "sabotaje"))
	_boton(botones, "Enviar expedición", _enviar_expedicion)
	_boton(botones, "Descargar puerto", func(): RastreoCarga.descargar_todo())
	_boton(botones, "Reponer suministros", _reponer)
	_boton(botones, "Soltar carga", func(): _resolver("soltar"))
	_boton(botones, "Luchar", func(): _resolver("luchar"))
	_boton(botones, "×4 velocidad", func(): Reloj.velocidad = 4.0 if Reloj.velocidad == 1.0 else 1.0)
	_boton(botones, "Pausa", func(): Reloj.pausado = not Reloj.pausado)

func _columna(padre: HBoxContainer, titulo: String, peso: float) -> RichTextLabel:
	var caja := _panel()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = peso
	padre.add_child(caja)
	var v := _interior(caja)
	v.add_child(_titulo(titulo))
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.add_theme_color_override("default_color", COLOR_TEXTO)
	v.add_child(rt)
	return rt

## Un PanelContainer estira a su hijo a la fuerza, así que el margen interior
## tiene que venir de un MarginContainer, no de offsets.
func _interior(caja: PanelContainer) -> VBoxContainer:
	var m := MarginContainer.new()
	for lado in ["left", "right"]:
		m.add_theme_constant_override("margin_" + lado, 10)
	for lado in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 8)
	caja.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	m.add_child(v)
	return v

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COLOR_PANEL
	estilo.corner_radius_top_left = 6
	estilo.corner_radius_top_right = 6
	estilo.corner_radius_bottom_left = 6
	estilo.corner_radius_bottom_right = 6
	p.add_theme_stylebox_override("panel", estilo)
	return p

func _titulo(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", COLOR_TENUE)
	return l

func _boton(padre: HBoxContainer, texto: String, accion: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(accion)
	padre.add_child(b)

# ---------------------------------------------------------------------------
# ACCIONES DE PRUEBA
# ---------------------------------------------------------------------------

## Simula el bloqueo naval: desaparece el aceite imperial. La herrería NO debe
## pararse — debe pasar sola a grasa de ballena y bajar la calidad del lote.
func _bloqueo_naval() -> void:
	Almacen.mermar("aceite_imperial", Almacen.cantidad("aceite_imperial"), "bloqueo naval")
	_apuntar("[b]La Corona bloqueó la ruta del Aceite Imperial.[/b] Veamos si la herrería aguanta.")

func _enviar_expedicion() -> void:
	var carga := { "seda_robada": 2, "tablon_tratado": 4 }
	var id := RastreoCarga.zarpar("bergantin", carga, 6, "Ruta de Portobello", 4)
	if id == "":
		_apuntar("[color=#c0392b]No se pudo zarpar: falta carga o no cabe.[/color]")

## Responde al primer informe de interceptación pendiente.
func _resolver(decision: String) -> void:
	for m in RastreoCarga.en_mar():
		if m["interceptado"]:
			RastreoCarga.resolver_interceptacion(m["id"], decision)
			var que := "Soltamos lastre y escapamos." if decision == "soltar" else "Presentamos batalla."
			_apuntar("%s — %s" % [m["id"], que])
			return
	_apuntar("[color=#7d8798]No hay ningún barco interceptado ahora mismo.[/color]")

func _reponer() -> void:
	for par in [["ron", 20], ["raciones", 25], ["doblon", 400], ["acero_imperial", 8],
			["carbon", 20], ["aceite_imperial", 4]]:
		Almacen.anadir(par[0], par[1], "mercader")
	_apuntar("Un mercader corrupto descarga suministros en el muelle.")

# ---------------------------------------------------------------------------
# REFRESCO
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	_lbl_reloj.text = Reloj.texto()

	_barra_motin.value = Motin.nivel
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Motin.color_barra()
	estilo.corner_radius_top_left = 4
	estilo.corner_radius_bottom_left = 4
	_barra_motin.add_theme_stylebox_override("fill", estilo)
	_lbl_motin.text = "MOTÍN  %d / 100   (%s)   ·   %d piratas" % [
		int(Motin.nivel), Motin.estado_texto(), Motin.tripulacion]

	_pintar_almacen()
	_pintar_estaciones()
	_pintar_flota()

func _pintar_almacen() -> void:
	var global := RastreoCarga.inventario_global()
	var claves := global.keys()
	claves.sort_custom(func(a, b): return BaseDeDatos.nombre_item(a) < BaseDeDatos.nombre_item(b))
	var lineas := ["[color=#7d8798]cofres · puerto · mar[/color]"]
	for id in claves:
		var g: Dictionary = global[id]
		if g["total"] <= 0:
			continue
		var reservado := int(Almacen.reservas.get(id, 0))
		var extra := ""
		if reservado > 0:
			extra = "  [color=#7d8798](%d apartado)[/color]" % reservado
		var flotando := ""
		if int(g["puerto"]) + int(g["mar"]) > 0:
			flotando = " [color=#5b9bd5]· %d · %d[/color]" % [g["puerto"], g["mar"]]
		lineas.append("%s  [b]%d[/b]%s%s" % [BaseDeDatos.nombre_item(id), g["cofres"], flotando, extra])
	_lbl_almacen.text = "\n".join(lineas)

func _pintar_estaciones() -> void:
	var lineas := []
	for e in estaciones:
		var r := BaseDeDatos.receta(e.receta_id)
		var nombre_r := r.nombre if r != null else e.receta_id
		var color := "#4caf50"
		if e.parada:
			color = "#c0392b"
		elif e.estado_texto() != "produciendo":
			color = "#7d8798"
		var barra := ""
		if not e.parada:
			var llenos := int(e.porcentaje() * 12)
			barra = "[color=#d4a017]%s[/color]%s" % ["█".repeat(llenos), "░".repeat(12 - llenos)]
		lineas.append("[color=%s]%s[/color]\n  %s  %s  [color=#7d8798]%d ⚒[/color]"
			% [color, _nombre(e.edificio_id), nombre_r, barra, e.trabajadores])
	var cuellos := Almacen.cuellos_activos()
	if not cuellos.is_empty():
		lineas.append("\n[color=#c0392b][b]EN ROJO[/b][/color]")
		for c in cuellos:
			lineas.append("[color=#c0392b]· %s: %s (%d, mín %d)[/color]"
				% [_nombre(c["estacion"]), BaseDeDatos.nombre_item(c["insumo"]), c["hay"], c["minimo"]])
	_lbl_estaciones.text = "\n".join(lineas)

func _pintar_flota() -> void:
	var lineas := []
	for m in RastreoCarga.en_mar():
		var aviso := ""
		if m["interceptado"]:
			aviso = "  [color=#e07b39]¡INTERCEPTADO![/color]"
		lineas.append("[color=#5b9bd5]%s[/color] · %s\n  %s — %d día(s)%s"
			% [m["id"], RastreoCarga.BARCOS[m["barco"]]["nombre"], m["destino"], m["dias_restantes"], aviso])
	for m in RastreoCarga.en_puerto():
		lineas.append("[color=#4caf50]%s[/color] · atracado, esperando descarga" % m["id"])
	if lineas.is_empty():
		lineas.append("[color=#7d8798]Ningún barco en ruta.[/color]")
	lineas.append("\n[color=#7d8798]PLANTEL[/color]\n" + Plantel.descripcion_plantel())
	_lbl_flota.text = "\n".join(lineas)

# ---------------------------------------------------------------------------

func _apuntar(texto: String) -> void:
	registro.append("[color=#7d8798]%s[/color]  %s" % [Reloj.texto(), texto])
	if registro.size() > 120:
		registro.pop_front()
	_lbl_registro.text = "\n".join(registro)

func _nombre(id_edificio: String) -> String:
	var e: EdificioData = BaseDeDatos.edificio(id_edificio)
	if e != null:
		return e.nombre
	return id_edificio

func _unhandled_input(evento: InputEvent) -> void:
	# Atajo: barra espaciadora = pausa. Cuando hay mucho ardiendo a la vez.
	if evento is InputEventKey and evento.pressed and evento.keycode == KEY_SPACE:
		Reloj.pausado = not Reloj.pausado
