class_name ParcelaCultivo
extends Interactuable

signal accion_realizada(parcela: ParcelaCultivo, accion: String, productos: Dictionary)

var definicion_id: String = ""
var identidad: Identidad = null
var casilla_pos := Vector2i.ZERO

func montar(p_definicion_id: String, clave_natural: String, casilla: Vector2i) -> bool:
	var def := BaseDeDatos.cultivo(p_definicion_id)
	if def == null:
		return false
	definicion_id = p_definicion_id
	casilla_pos = casilla
	identidad = Entidades.identificar("parcela", definicion_id, clave_natural)
	Entidades.vincular(identidad, self)
	name = "Parcela_%s_%s" % [definicion_id, identidad.instancia]
	position = Iso.centro_v(casilla)
	CultivosMundo.registrar(self)
	queue_redraw()
	return true

func definicion() -> Resource:
	return BaseDeDatos.cultivo(definicion_id)

func casilla() -> Vector2i:
	return casilla_pos

func disponible(quien: Node) -> bool:
	return quien != null and quien.has_method("inventario")

func texto_accion() -> String:
	var e := CultivosMundo.etapa(identidad.instancia if identidad != null else "")
	if e == 0:
		return "Sembrar %s" % definicion().nombre
	if e == 3:
		return "Cosechar %s" % definicion().nombre
	return "Cultivo creciendo"

func interactuar(quien: Node) -> void:
	if not disponible(quien) or identidad == null:
		return
	var inv: Inventario = quien.inventario()
	var e := CultivosMundo.etapa(identidad.instancia)
	if e == 0:
		if CultivosMundo.sembrar(identidad.instancia, inv):
			accion_realizada.emit(self, "sembrar", {})
	elif e == 3:
		var resultado := CultivosMundo.cosechar(identidad.instancia, inv)
		if bool(resultado.get("ok", false)):
			accion_realizada.emit(self, "cosechar", resultado.get("productos", {}))

func _draw() -> void:
	var suelo := GlobalColors.PALETA["marron_profundo"]
	draw_ellipse(Vector2(0, 2), 14.0, 6.0, suelo)
	var e := CultivosMundo.etapa(identidad.instancia if identidad != null else "")
	if e == 0:
		draw_line(Vector2(-8, -1), Vector2(8, -1), GlobalColors.PALETA["arena_madera"], 2.0)
		return
	var color := GlobalColors.PALETA["verde_base"] if e < 3 else GlobalColors.PALETA["oro_llama"]
	for punto in [Vector2(-7, -7), Vector2(0, -11), Vector2(7, -6)]:
		draw_line(punto + Vector2(0, 8), punto, GlobalColors.PALETA["verde_abisal"], 2.0)
		draw_circle(punto, 3.0 if e == 1 else 5.0, color)
