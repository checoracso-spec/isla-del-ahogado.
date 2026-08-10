extends Node
## Fuente única de verdad para los colores usados desde código.
##
## El arte rasterizado conserva su propia paleta en los PNG. Este autoload
## estandariza UI, dibujo procedural y parámetros que la lógica envíe a
## shaders, sin acoplar los sistemas a un sprite concreto.

const DIRECCION_LUZ_2D := Vector2(-1, -1) # Arriba-izquierda.
const BORDE_SELECCION_PX := 1

const PALETA := {
	# Sombras y vacíos
	"vacio_abismal": Color("#0f0f1b"),
	"azul_noche": Color("#162038"),
	"gris_oscuro": Color("#252536"),
	"marron_profundo": Color("#291814"),

	# Piedra y metales opacos
	"gris_base": Color("#3d3d52"),
	"gris_claro": Color("#5e5e73"),
	"acero_gris": Color("#8b8b9e"),
	"plata_salitre": Color("#c2c2d1"),

	# Maderas y cueros
	"madera_oscura": Color("#42241c"),
	"madera_base": Color("#663b2a"),
	"madera_clara": Color("#8f5c3b"),
	"arena_madera": Color("#c48d5f"),

	# Telas, sangre y fuego
	"rojo_sangre": Color("#4a1528"),
	"rojo_calido": Color("#822633"),
	"rojo_brillante": Color("#bd403a"),
	"naranja_fuego": Color("#e87a41"),

	# Oro y luz
	"oro_llama": Color("#f5c051"),
	"luz_palida": Color("#fff3b5"),
	"blanco_puro": Color("#ffffff"),

	# Agua y magia
	"oceano_sombra": Color("#264063"),
	"azul_base": Color("#3a6b8f"),
	"cian_magico": Color("#5cb2b5"),
	"espuma_marina": Color("#98e0d5"),

	# Vegetación y veneno
	"verde_abisal": Color("#183028"),
	"verde_base": Color("#2c543b"),
	"verde_claro": Color("#4a804d"),
	"verde_brillo": Color("#82b06b"),
	"verde_toxico": Color("#a8ca58"),

	# Piel
	"piel_sombra": Color("#593e47"),
	"piel_oscura": Color("#8c5d62"),
	"piel_base": Color("#c98a82"),
	"piel_brillo": Color("#ebb3a4"),
}

func color(nombre: String, respaldo: Color = Color("#0f0f1b")) -> Color:
	return PALETA.get(nombre, respaldo)

func con_alpha(nombre: String, alpha: float) -> Color:
	var base: Color = color(nombre)
	return Color(base.r, base.g, base.b, clampf(alpha, 0.0, 1.0))

func get_color_salud() -> Color:
	return PALETA["rojo_brillante"]

func get_color_estamina() -> Color:
	return PALETA["verde_claro"]

func get_color_energia() -> Color:
	return PALETA["cian_magico"]

func get_color_interaccion() -> Color:
	return PALETA["oro_llama"]

func get_color_peligro() -> Color:
	return PALETA["naranja_fuego"]

func get_color_estado_alterado() -> Color:
	return PALETA["verde_toxico"]

func get_color_seleccion() -> Color:
	return PALETA["blanco_puro"]

func get_color_vacio() -> Color:
	return PALETA["vacio_abismal"]
