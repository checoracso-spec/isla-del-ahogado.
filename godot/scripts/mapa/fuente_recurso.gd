class_name FuenteRecurso
extends Interactuable
const FuenteRecursoDataScript := preload("res://scripts/datos/fuente_recurso_data.gd")
## Una fuente física del mundo: restos, árbol, veta o futura parcela.
##
## La instancia sólo contiene identidad y presentación. La cantidad viva la
## administra RecursosMundo, para que el nodo pueda desaparecer y reaparecer
## sin perder el estado.

signal recolectado(fuente: Node, ciclos: int, productos: Dictionary)

var definicion_id: String = ""
var identidad: Identidad = null
var casilla_pos: Vector2i = Vector2i.ZERO

func montar(p_definicion_id: String, clave_natural: String, casilla: Vector2i) -> bool:
	var def := BaseDeDatos.fuente(p_definicion_id)
	if def == null:
		push_warning("FuenteRecurso: definición inexistente '%s'" % p_definicion_id)
		return false
	definicion_id = p_definicion_id
	casilla_pos = casilla
	identidad = Entidades.identificar("recurso", definicion_id, clave_natural)
	Entidades.vincular(identidad, self)
	name = "Recurso_%s_%s" % [definicion_id, identidad.instancia]
	position = Iso.centro_v(casilla)
	RecursosMundo.registrar(self)
	queue_redraw()
	return true

func definicion() -> Resource:
	return BaseDeDatos.fuente(definicion_id)

func cantidad() -> int:
	return RecursosMundo.cantidad(identidad.instancia if identidad != null else "")

func disponible(_quien: Node) -> bool:
	return cantidad() > 0

func texto_accion() -> String:
	var def := definicion()
	if cantidad() <= 0:
		return "Agotado"
	return "Recolectar %s" % (def.nombre if def != null else definicion_id)

func interactuar(quien: Node) -> void:
	if quien == null or not quien.has_method("inventario"):
		return
	var destino: Inventario = quien.inventario()
	var resultado := recolectar(destino)
	if int(resultado.get("ciclos", 0)) > 0:
		recolectado.emit(self, int(resultado["ciclos"]), resultado["productos"])

## Punto de entrada común para jugadores, NPCs y animales recolectores.
func recolectar(destino: Inventario, ciclos: int = 1) -> Dictionary:
	if identidad == null or destino == null:
		return {"ciclos": 0, "productos": {}}
	return RecursosMundo.recolectar(identidad.instancia, destino, ciclos)

func casilla() -> Vector2i:
	return casilla_pos

func _draw() -> void:
	if cantidad() <= 0:
		draw_ellipse(Vector2.ZERO, 15.0, 6.0,
			GlobalColors.con_alpha("gris_base", 0.45))
		return
	var sombra: Color = GlobalColors.PALETA["marron_profundo"]
	draw_ellipse(Vector2(0, 3), 17.0, 7.0, sombra)
	match definicion_id:
		"restos_naufragio":
			# Silueta grande y contrastada: tablones, proa rota y herraje.
			draw_colored_polygon(PackedVector2Array([
				Vector2(-17, -2), Vector2(-8, -12), Vector2(12, -10),
				Vector2(17, -3), Vector2(6, 4), Vector2(-10, 4)]),
				GlobalColors.PALETA["madera_oscura"])
			draw_line(Vector2(-15, -3), Vector2(9, -7),
			GlobalColors.PALETA["madera_clara"], 4.0)
			draw_line(Vector2(-10, 1), Vector2(14, -3),
			GlobalColors.PALETA["arena_madera"], 3.0)
			draw_line(Vector2(-5, -10), Vector2(-1, 2),
			GlobalColors.PALETA["madera_base"], 2.0)
			draw_circle(Vector2(9, -11), 4.0, GlobalColors.PALETA["acero_gris"])
			draw_circle(Vector2(9, -11), 2.0, GlobalColors.PALETA["plata_salitre"])
			draw_line(Vector2(-18, -4), Vector2(-22, -12),
			GlobalColors.PALETA["oro_llama"], 2.0)
			draw_circle(Vector2(-22, -13), 2.0, GlobalColors.PALETA["espuma_marina"])
			# Mástil roto y bandera: el punto de recolección debe leerse
			# desde lejos sin convertirse en un marcador de depuración.
			draw_line(Vector2(-3, -5), Vector2(-7, -34),
			GlobalColors.PALETA["madera_oscura"], 3.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-7, -34), Vector2(4, -30), Vector2(-7, -26)]),
				GlobalColors.PALETA["rojo_calido"])
			draw_line(Vector2(-7, -34), Vector2(1, -31),
			GlobalColors.PALETA["oro_llama"], 1.0)
		"arbol_manglar":
			draw_rect(Rect2(-3, -17, 6, 18), GlobalColors.PALETA["madera_oscura"])
			draw_circle(Vector2(-7, -18), 8.0, GlobalColors.PALETA["verde_base"])
			draw_circle(Vector2(5, -21), 9.0, GlobalColors.PALETA["verde_claro"])
			draw_circle(Vector2(0, -28), 8.0, GlobalColors.PALETA["verde_brillo"])
		"veta_azufre":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-13, 0), Vector2(-7, -11), Vector2(2, -14),
				Vector2(13, -5), Vector2(9, 4), Vector2(-5, 7)]),
				GlobalColors.PALETA["gris_base"])
			draw_circle(Vector2(-2, -7), 3.0, GlobalColors.PALETA["oro_llama"])
			draw_circle(Vector2(6, -3), 2.0, GlobalColors.PALETA["naranja_fuego"])
		"semillero_isla":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-9, -1), Vector2(-7, -13), Vector2(7, -13),
				Vector2(10, -1), Vector2(5, 4), Vector2(-6, 4)]),
				GlobalColors.PALETA["arena_madera"])
			draw_line(Vector2(-7, -11), Vector2(7, -11),
				GlobalColors.PALETA["madera_oscura"], 2.0)
			draw_line(Vector2(-2, -13), Vector2(-4, -22),
				GlobalColors.PALETA["verde_base"], 2.0)
			draw_line(Vector2(1, -13), Vector2(5, -21),
				GlobalColors.PALETA["verde_claro"], 2.0)
		_:
			draw_circle(Vector2(0, -10), 9.0, GlobalColors.PALETA["madera_clara"])
