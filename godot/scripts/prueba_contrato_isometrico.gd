extends Node

## Benchmark MAREA-002: contrato de rejilla isométrica 2:1.
## Verifica la fuente de verdad de Iso y el TileSet real usado por Marea.

var correctas := 0
var fallos := 0

func _ready() -> void:
	_comprobar(Iso.ANCHO == 128, "ancho canónico 128")
	_comprobar(Iso.ALTO == 64, "alto canónico 64")
	_comprobar(is_equal_approx(float(Iso.ANCHO) / float(Iso.ALTO), 2.0), "ratio 2:1")
	_comprobar(Iso.ORIGEN == Vector2(64.0, 32.0), "origen centrado del tile")

	for celda in [Vector2i(-4, -3), Vector2i(0, 0), Vector2i(1, 2), Vector2i(7, 5), Vector2i(12, 9), Vector2i(20, 20)]:
		var centro := Iso.centro_v(celda)
		_comprobar(Iso.a_tile(centro) == celda, "round-trip celda %s" % celda)
		var esquinas := Iso.esquinas(celda.x, celda.y)
		_comprobar(esquinas.size() == 4, "cuatro esquinas %s" % celda)
		_comprobar(Iso.apoyo(celda.x, celda.y) == centro + Vector2(0.0, 32.0),
			"apoyo alineado %s" % celda)

	var tileset := ConstructorTileset.new().construir(20260920)
	_comprobar(tileset != null, "TileSet construido")
	if tileset != null:
		_comprobar(tileset.tile_shape == TileSet.TILE_SHAPE_ISOMETRIC, "shape isométrico real")
		_comprobar(tileset.tile_layout == TileSet.TILE_LAYOUT_DIAMOND_DOWN, "layout diamond down")
		_comprobar(tileset.tile_size == Vector2i(128, 64), "tile size 128x64")

	print("MAREA-002 GRID CONTRACT: %d/%d PASS" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		correctas += 1
		print("  OK    ", nombre)
	else:
		fallos += 1
		push_error("FALLO  " + nombre)
