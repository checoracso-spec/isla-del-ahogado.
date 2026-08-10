class_name TransicionZona
extends Interactuable
## Paso entre dos zonas que pertenecen al mismo edificio.
##
## La escalera sólo describe el destino y emite una petición. No crea zonas,
## no mueve actores y no toca la cámara; esas responsabilidades siguen siendo
## exclusivas del gestor `Interiores`.

signal atravesada(transicion: TransicionZona, quien: Node)

var destino_zona: String = ""
var entrada_destino: Vector2i = Vector2i(1, 1)
var casilla_propia: Vector2i = Vector2i.ZERO
var accion: String = "Usar"
var _sprite: Sprite2D = null

func _ready() -> void:
	super()
	alcance = 1.8

func usar_asset(clave: String) -> void:
	if not Assets.existe(clave):
		return
	_sprite = Assets.sprite(clave)
	add_child(_sprite)

func texto_accion() -> String:
	return accion

func disponible(_quien: Node) -> bool:
	return destino_zona != "" and BaseDeDatos.interior(destino_zona) != null

func interactuar(quien: Node) -> void:
	atravesada.emit(self, quien)

func casilla() -> Vector2i:
	return casilla_propia
