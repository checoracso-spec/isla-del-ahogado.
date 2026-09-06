extends Node

## Economía global: doblones, precios base, compraventa y economía de la isla.
## La moneda oficial del juego será el doblón.

var doubloons: int = 0

signal doubloons_changed(amount: int)

func add_doubloons(amount: int) -> void:
	doubloons = maxi(0, doubloons + amount)
	doubloons_changed.emit(doubloons)

func can_afford(amount: int) -> bool:
	return amount >= 0 and doubloons >= amount

func spend_doubloons(amount: int) -> bool:
	if not can_afford(amount):
		return false
	doubloons -= amount
	doubloons_changed.emit(doubloons)
	return true

func buy(item: Item, quantity: int, price_each: int) -> bool:
	if item == null or quantity <= 0 or not can_afford(quantity * price_each):
		return false
	if not InventorySystem.can_add_item(item, quantity):
		return false
	spend_doubloons(quantity * price_each)
	return InventorySystem.add_item(item, quantity)

func sell(item_id: String, quantity: int, price_each: int) -> bool:
	if quantity <= 0 or not InventorySystem.remove_item(item_id, quantity):
		return false
	add_doubloons(quantity * price_each)
	return true
