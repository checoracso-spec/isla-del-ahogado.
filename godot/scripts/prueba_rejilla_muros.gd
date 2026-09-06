extends Node

## Prueba aislada de las celdas murales del editor.
## No modifica BaseDeDatos ni el layout guardado.

const ComparadorScript := preload("res://scripts/comparador_herreria.gd")

var correctas := 0
var fallos := 0

func _ready() -> void:
	var comparador := ComparadorScript.new()
	add_child(comparador)
	await get_tree().process_frame
	await get_tree().process_frame
	var editor := comparador.get_node_or_null("InteriorLayoutEditor") as InteriorLayoutEditor
	var interior: InteriorEscena = null
	for hijo in comparador.get_children():
		if hijo is InteriorEscena:
			interior = hijo
			break
	_comprobar(editor != null, "editor mural montado")
	_comprobar(interior != null, "interior mural montado")
	if editor == null or interior == null:
		_finalizar(comparador)
		return

	var casilla := Vector2i(2, 0)
	var puntos := editor._puntos_celda_muro_global(casilla, "x")
	var centro := (puntos[0] + puntos[1] + puntos[2] + puntos[3]) * 0.25
	var info := editor._muro_celda_bajo_cursor(centro)
	_comprobar(not info.is_empty(), "la celda mural se puede detectar con el cursor")
	_comprobar(str(info.get("eje", "")) == "x", "la celda conserva el eje X")
	var muro := editor._buscar_muro_en_celda(casilla, "x")
	_comprobar(muro != null, "la celda mural inicial tiene un nodo")
	if muro != null:
		var posicion_original := muro.position
		muro.visible = false
		muro.set_meta("layout_oculto_por_boton", true)
		editor._asset_activo = str(interior.definicion.asset_muro_oeste)
		editor._colocando_asset = true
		var reactivado := editor._colocar_segmento_muro_celda(casilla, "x")
		_comprobar(reactivado == muro, "colocar en una celda existente reutiliza el nodo")
		_comprobar(muro.visible, "colocar reactiva el tramo mural")
		_comprobar(muro.position == posicion_original, "el tramo reutilizado conserva el ancla Iso")
		_comprobar(editor._buscar_muro_en_celda(casilla, "x") == muro, "no se crea stacking en el mismo tramo")
		editor._seleccionado = muro
		editor._seleccionados = [muro]
		editor._ocultar_seleccionado()
		_comprobar(not muro.visible, "Supr puede quitar un tramo mural")
		var restaurado := editor._colocar_segmento_muro_celda(casilla, "x")
		_comprobar(restaurado == muro and muro.visible, "la misma celda puede rellenarse de nuevo")

	_finalizar(comparador)

func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		correctas += 1
		print("  OK    ", nombre)
	else:
		fallos += 1
		push_error("FALLO  " + nombre)

func _finalizar(comparador: Node) -> void:
	print("PRUEBA_REJILLA_MUROS: %d/%d" % [correctas, correctas + fallos])
	comparador.queue_free()
	get_tree().quit(0 if fallos == 0 else 1)
