extends Node

var correctas := 0
var fallos := 0

func _ready() -> void:
	_comprobar("el alias de herrería existe", DioramasExternos.existe("herreria_ref"))
	var claves := DioramasExternos.claves_pack()
	_comprobar("el catálogo descubre los 67 PNG", claves.size() == 67, str(claves.size()))
	_comprobar("las claves del pack son estables", claves == _claves_esperadas())
	_comprobar("el primer archivo tiene ruta válida",
		claves.is_empty() or DioramasExternos.existe(claves[0]))
	_comprobar("la imagen seleccionada carga como textura",
		DioramasExternos.textura("herreria_ref") != null)
	print("=== %d/%d comprobaciones de dioramas externos ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _claves_esperadas() -> Array[String]:
	var resultado: Array[String] = []
	for i in range(1, 68):
		resultado.append("pack_%02d" % i)
	return resultado

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s %s" % [nombre, detalle])
