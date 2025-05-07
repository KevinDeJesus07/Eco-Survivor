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
	var test = load("res://data/resources/items/item1.tres")
	
	if test:
		add_item(test, 0)

func move_or_swap_item_in_slots(from_idx: int, to_idx: int):
	if from_idx < 0 or from_idx >= slots.size() or to_idx < 0 or to_idx >= slots.size() or from_idx == to_idx:
		printerr("InventoryManager: Índices de slot inválidos para mover/intercambiar: from ", from_idx, " to ", to_idx)
		return
		
	if slots[from_idx] == null:
		printerr("InventoryManager: Intento de mover desde un slot origen vacío: ", from_idx)
		return
	
	print("InventoryManager: Intercambiando contenido del slot [", from_idx, "] con el slot [", to_idx, "]")
	
	var temp_item_at_target = slots[to_idx]
	slots[to_idx] = slots[from_idx]
	slots[from_idx] = temp_item_at_target
	
	inventory_changed.emit()
