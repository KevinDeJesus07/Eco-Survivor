extends Node

signal inventory_changed

var items: Dictionary = {}

@export var max_slots: int = 20

var slots: Array = []

func add_item(item_data: ItemData, quantity_to_add: int = 1):
	if not is_instance_valid(item_data):
		printerr("InventoryManager: Se intentó añadir un ItemData inválido")
		return quantity_to_add
		
	var remaining_quantity = quantity_to_add
	print("Intentando añadir ", remaining_quantity, " de ", item_data.item_name)
	
	for i in range(slots.size()):
		if remaining_quantity <= 0: break
		
		var current_slot = slots[i]
		if current_slot != null and current_slot["item"] == item_data and current_slot["quantity"] < item_data.stack_size:
			var space_available = item_data.stack_size - current_slot["quantity"]
			var amount_to_add_here = min(remaining_quantity, space_available)
			
			current_slot["quantity"] += amount_to_add_here
			remaining_quantity -= amount_to_add_here
			print(" Añadido ", amount_to_add_here, " a slot existente ", i, ". Retsnate: ", remaining_quantity)
	
	if remaining_quantity > 0:
		for i in range(slots.size()):
			if remaining_quantity <= 0: break
				
			if slots[i] == null:
				var amount_to_add_here = min(remaining_quantity, item_data.stack_size)
					
				slots[i] = {"item": item_data, "quantity": amount_to_add_here}
				remaining_quantity -= amount_to_add_here
				print(" Creado nuevo stack en slot vacío ", i, " con ", amount_to_add_here, ". Restante: ", remaining_quantity)
					
	inventory_changed.emit()
	if remaining_quantity > 0:
		print("Inventario lleno. No se puedieron añadir ", remaining_quantity, " de ", item_data.item_name)
		
	return remaining_quantity
	
	
	
func get_items() -> Dictionary:
	return items
	
func get_slots_data() -> Array:
	return slots
	
func remove_item_from_slot(slot_index: int, quantity_to_remove: int = 1):
	if slot_index < 0 or slot_index >= slots.size() or slots[slot_index] == null:
		printerr("Intento de quitar ítem de slot inválido o vacío: ", slot_index)
		return
		
	slots[slot_index]["quantity"] -= quantity_to_remove
	if slots[slot_index]["quantity"] <= 0:
		slots[slot_index] = null
		
	inventory_changed.emit()
	
func _ready():
	slots.resize(max_slots)
	print("InventoryManager listo con ", max_slots, " slots.")
	var test = load("res://data/resources/items/test_item.tres")
	
	# if test:
	#	add_item(test, 0)
