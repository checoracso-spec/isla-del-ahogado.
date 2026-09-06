extends SceneTree

func _initialize() -> void:
	var escena := load("res://escenas/comparador_herreria.tscn") as PackedScene
	var instancia := escena.instantiate()
	root.add_child(instancia)
	await process_frame
	await process_frame
	await process_frame
	var imagen := get_root().get_texture().get_image()
	imagen.save_png("res://docs/assets_pipeline/comparador_herreria_neutro.png")
	print("CAPTURA_COMPARADOR_OK")
	quit()
