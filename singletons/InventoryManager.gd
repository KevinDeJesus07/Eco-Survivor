extends Node

signal inventory_changed

var items: Dictionary = {}

@export var max_slots: int = 20

var slots: Array = []

var log_category: String = "INVENTORY_MANAGER"

func add_item(item: Item, quantity: int = 1):
	if not is_instance_valid(item):
		Logger.error(log_category, "Se intento añadir un 'Item' inválido", self)
		return quantity
	
	if not quantity > 0:
		Logger.warn(log_category, "Se intento añadir cantidad 0  o negativa de " + str(item.name), self)
		return 0
	
	var remaining = quantity
	var quantity_added = 0
	Logger.info(log_category, "Intentando añadir " + str(remaining) + " de " + str(item.name), self)
	
	for i in range(slots.size()):
		if remaining <= 0:
			break
		
		var current_slot = slots[i]
		
		if current_slot == null:
			continue
		
		if not current_slot["item"] == item:
			continue
			
		if current_slot["quantity"] >= item.stack_max:
			continue
		
		var space_available = item.stack_max - current_slot["quantity"]
		var amount_to_add = min(remaining, space_available)
			
		current_slot["quantity"] += amount_to_add
		remaining -= amount_to_add
		quantity_added += amount_to_add
		Logger.debug(log_category, "Añadiendo " + str(amount_to_add) + " a slot existente " + str(i) + ". Restante: " + str(remaining))
	
	# Slots vacios
	if remaining > 0:
		Logger.debug(log_category, "Items restantes (" + str(remaining) + "), buscando slots vacíos.", self)
		for i in range(slots.size()):
			if remaining <= 0:
				break
				
			if slots[i] == null:
				var amount_to_add = min(remaining, item.stack_max)
				slots[i] = {"item": item, "quantity": amount_to_add}
				remaining -= amount_to_add
				quantity_added += amount_to_add
				Logger.debug(log_category, "Creando nuevo stack en slot vacío [" + str(i) + "] con " + str(amount_to_add) + ". Restante: " + str(remaining), self)
	
	if  quantity_added > 0:
		Logger.debug(log_category, "Emitiendo señal 'inventory_changed'.", self)
		inventory_changed.emit()
		
	if remaining > 0:
		Logger.warn(log_category, "Inventario lleno. No se pudieron añadir " + str(remaining) + " de " + str(item.name), self)
	
	return remaining
	
func get_items() -> Dictionary:
	return items
	
func get_slots() -> Array:
	return slots
	
func remove_item_from_slot(slot_idx: int, quantity: int = 1):
	if not quantity > 0:
		Logger.warn(log_category, "Intento de quitar cantidad <= 0 (" + str(quantity) + ") del slot [" + str(slot_idx) + "].", self)
		return
	
	if slot_idx < 0 or slot_idx >= slots.size():
		Logger.error(log_category, "Intento de quitar item de slot con índice fuera de rango: " + str(slot_idx), self)
		return
		
	if slots[slot_idx] == null:
		Logger.warn(log_category, "Intento de quitar ítem de slot que ya está vacío: " + str(slot_idx), self)
		return
		
	var curr_quantity = slots[slot_idx]["quantity"]
	var item_name = "Unknown Item"
	if is_instance_valid(slots[slot_idx]["item"]):
		item_name = slots[slot_idx]["item"].name
		
	var curr_quantity_to_remove = min(quantity, curr_quantity)
	
	Logger.debug(log_category, "Quitando " + str(curr_quantity_to_remove) + " de '" + item_name + "' del slot [" + str(slot_idx) + "]. (Cantidad original: " + str(curr_quantity) + ", Pedido: " + str(quantity) + ")", self)
	
	slots[slot_idx]["quantity"] -= curr_quantity_to_remove
	if slots[slot_idx]["quantity"] <= 0:
		Logger.info(log_category, "Slot [" + str(slot_idx) + "] vaciado (era " + item_name + ").", self)
		slots[slot_idx] = null
	else:
		Logger.debug(log_category, "Slot [" + str(slot_idx) + "] nueva cantidad para '" + item_name + "': " + str(slots[slot_idx]["quantity"]), self)
	
	Logger.debug(log_category, "Emitiendo inventory_changed después de remove_item_from_slot.", self)
	inventory_changed.emit()
	return curr_quantity_to_remove
	
func _ready():
	slots.resize(max_slots)

func move_or_swap_item_in_slots(from_idx: int, to_idx: int):
	if from_idx == to_idx:
		Logger.debug(log_category, "Intento de mover/intercambiar un slot consigo mismo (índice " + str(from_idx) + ").", self)
		return
		
	if from_idx < 0 or from_idx >= slots.size():
		Logger.error(log_category, "Índice 'from_idx' inválido (" + str(from_idx) + ") para mover/intercambiar.", self)
		return
		
	if to_idx < 0 or to_idx >= slots.size():
		Logger.error(log_category, "Índice 'to_idx' inválido (" + str(to_idx) + ") para mover/intercambiar.", self)
		return
		
	if slots[from_idx] == null:
		Logger.warn(log_category, "Intento de mover/intercambiar desde un slot origen vacío: " + str(from_idx), self)
		return
		
	var item_name_from = slots[from_idx]["item"].name
	var item_name_to = "Vacío"
	
	if is_instance_valid(slots[to_idx]) and is_instance_valid(slots[to_idx]["item"]):
		item_name_to = slots[to_idx]["item"].name
		
	Logger.info(log_category, "Intercambiando slot [" + str(from_idx) + "] ('" + item_name_from + "') con slot [" + str(to_idx) + "] ('" + item_name_to + "')", self)
	
	var temp = slots[to_idx]
	slots[to_idx] = slots[from_idx]
	slots[from_idx] = temp
	
	Logger.debug(log_category, "Emitiendo inventory_changed después de move_or_swap_item_in_slots.", self)
	inventory_changed.emit()
