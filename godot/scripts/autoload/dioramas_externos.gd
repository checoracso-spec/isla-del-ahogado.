extends Node

## Catálogo opcional de arte externo. La escena sólo conoce una clave.
## No participa en colisiones, transitabilidad ni guardado del juego.

const CATALOGO := {
	"herreria_ref": "res://assets/externos/room_diorama/isometricroomtileset (60).png",
}

const DIRECTORIO_PACK := "res://assets/externos/room_diorama"
var _catalogo: Dictionary = {}

func _ready() -> void:
	_catalogo = CATALOGO.duplicate()
	var directorio := DirAccess.open(DIRECTORIO_PACK)
	if directorio == null:
		return
	var archivos := directorio.get_files()
	archivos.sort()
	var indice := 1
	for archivo in archivos:
		if not str(archivo).to_lower().ends_with(".png"):
			continue
		_catalogo["pack_%02d" % indice] = DIRECTORIO_PACK + "/" + str(archivo)
		indice += 1

func existe(clave: String) -> bool:
	return _catalogo.has(clave) and FileAccess.file_exists(str(_catalogo[clave]))

func ruta(clave: String) -> String:
	return str(_catalogo.get(clave, ""))

func claves_pack() -> Array[String]:
	var resultado: Array[String] = []
	for clave in _catalogo:
		if str(clave).begins_with("pack_"):
			resultado.append(str(clave))
	resultado.sort()
	return resultado

func textura(clave: String) -> Texture2D:
	if not existe(clave):
		return null
	var imagen := Image.load_from_file(ruta(clave))
	if imagen == null:
		return null
	return ImageTexture.create_from_image(imagen)
