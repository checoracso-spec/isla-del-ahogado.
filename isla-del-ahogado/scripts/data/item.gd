class_name Item
extends Resource

## Recurso de objeto genérico para inventario y sistemas futuros.

@export var item_id: String = ""
@export var item_name: String = "Objeto"
@export var icon: Texture2D
@export_range(1, 999, 1) var max_stack: int = 99

