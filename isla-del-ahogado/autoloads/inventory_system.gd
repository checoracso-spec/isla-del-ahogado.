extends Node

## Inventario genérico del jugador: 20 slots, apilado y señal de actualización.
## Los sistemas de contenido pueden llamar públicamente a add_item().

signal inventory_changed

const SLOT_COUNT := 20
var slots: Array[Dictionary] = []

func _ready() -> void:
	for _index in range(SLOT_COUNT):
		slots.append({})

func add_item(item: Item, cantidad: int = 1) -> bool:
	if item == null or cantidad <= 0:
		return false
	if not can_add_item(item, cantidad):
		return false
	var remaining := cantidad
	for index in range(slots.size()):
		var slot := slots[index]
		if slot.is_empty() or not _items_match(slot.get("item") as Item, item):
			continue
		var available: int = item.max_stack - int(slot.get("quantity", 0))
		var added: int = mini(available, remaining)
		slot["quantity"] = int(slot.get("quantity", 0)) + added
		slots[index] = slot
		remaining -= added
		if remaining == 0:
			inventory_changed.emit()
			return true
	for index in range(slots.size()):
		if not slots[index].is_empty():
			continue
		var added: int = mini(item.max_stack, remaining)
		slots[index] = {"item": item, "quantity": added}
		remaining -= added
		if remaining == 0:
			break
	inventory_changed.emit()
	return remaining == 0

func can_add_item(item: Item, cantidad: int = 1) -> bool:
	if item == null or cantidad <= 0:
		return false
	var capacity := 0
	for slot in slots:
		if slot.is_empty():
			capacity += item.max_stack
		elif _items_match(slot.get("item") as Item, item):
			capacity += item.max_stack - int(slot.get("quantity", 0))
	return capacity >= cantidad

func _items_match(first: Item, second: Item) -> bool:
	if first == null or second == null:
		return false
	return first == second or (not first.item_id.is_empty() and first.item_id == second.item_id)

func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= slots.size():
		return {}
	return slots[index]

func count_item(item_id: String) -> int:
	var total := 0
	for slot in slots:
		var item: Item = slot.get("item") as Item
		if item != null and item.item_id == item_id:
			total += int(slot.get("quantity", 0))
	return total

func remove_item(item_id: String, cantidad: int = 1) -> bool:
	if cantidad <= 0 or count_item(item_id) < cantidad:
		return false
	var remaining := cantidad
	for index in range(slots.size()):
		var slot := slots[index]
		var item: Item = slot.get("item") as Item
		if item == null or item.item_id != item_id:
			continue
		var removed := mini(remaining, int(slot.get("quantity", 0)))
		remaining -= removed
		var left := int(slot.get("quantity", 0)) - removed
		slots[index] = {} if left <= 0 else {"item": item, "quantity": left}
		if remaining == 0:
			inventory_changed.emit()
			return true
	return false
