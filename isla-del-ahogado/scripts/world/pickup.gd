extends Interactable

## Recolectable de prueba: añade un Item al inventario y desaparece.

@export var item: Item
@export var quantity := 1

func _ready() -> void:
	super._ready()
	if item == null:
		item = Item.new()
		item.item_id = "botella_ron"
		item.item_name = "Botella de ron"
		item.max_stack = 20
	queue_redraw()

func interact(interactor: Node) -> bool:
	if not InventorySystem.can_add_item(item, quantity):
		return false
	if not super.interact(interactor):
		return false
	if not InventorySystem.add_item(item, quantity):
		return false
	queue_free()
	return true

func _draw() -> void:
	draw_circle(Vector2(0.0, 8.0), 10.0, Color(0.02, 0.03, 0.04, 0.35))
	draw_rect(Rect2(-8.0, -10.0, 16.0, 18.0), Color("#6c392c"), true)
	draw_rect(Rect2(-8.0, -10.0, 16.0, 18.0), Color("#f3c77a"), false, 2.0)
	draw_rect(Rect2(-5.0, -15.0, 10.0, 5.0), Color("#c9a66b"), true)
	draw_line(Vector2(-5.0, -4.0), Vector2(5.0, 4.0), Color("#b87350"), 2.0)
	draw_line(Vector2(5.0, -4.0), Vector2(-5.0, 4.0), Color("#b87350"), 2.0)
