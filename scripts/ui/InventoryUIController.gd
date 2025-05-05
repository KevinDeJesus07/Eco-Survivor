extends PanelContainer

@onready var slot_grid: GridContainer = $MarginContainer/SlotGrid

const InventorySlotScene = preload("res://scenes/ui/InventorySlot.tscn")

@export var inventory_slots_count: int = 20

func _ready() -> void:
	self.visible = false
	populate_grid()

	# Conectar a la señal del InventoryManager para actualizar cuando cambie
	if InventoryManager:
		# Conectar la función 'update_display' de este script a la señal 'inventory_changed' del singleton
		InventoryManager.inventory_changed.connect(update_display)
		update_display()
		print("InventoryUI listo y conectado a InventoryManager.") # Para depuración
	else:
		# Mensaje de error si el singleton no se cargó correctamente
		printerr("InventoryUIController: ¡InventoryManager no encontrado en Carga automática!")

func _process(delta: float) -> void:
	pass

# Función para crear los slots visuales vacíos y añadirlos a la cuadrícula
func populate_grid() -> void:
	# Limpiar slots anteriores si esta función se llamara de nuevo (poco probable aquí)
	for child in slot_grid.get_children():
		child.queue_free()

	# Crear el número especificado de instancias de InventorySlot
	for i in inventory_slots_count:
		var slot_instance = InventorySlotScene.instantiate()
		slot_grid.add_child(slot_instance)


# Función para actualizar los slots con los datos actuales del inventario
func update_display() -> void:
	# Salir si el InventoryManager no está disponible
	if not InventoryManager:
		printerr("InventoryUIController: InventoryManager no disponible en update_display.")
		return

	var inventory_data: Array = InventoryManager.get_slots_data()
	var ui_slots: Array = slot_grid.get_children()
	
	if inventory_data.size() != ui_slots.size():
		printerr("InventoryUIController: Discrepancia entre slots de datos (%d) y slots de UI (%d)" % [inventory_data.size(), ui_slots.size()])

	var num_slots_to_update = min(inventory_data.size(), ui_slots.size())
	for i in range(num_slots_to_update):
		var slot_data = inventory_data[i]
		var slot_node = ui_slots[i]
		
		if not slot_node or not slot_node is Panel:
			printerr("InventoryUIController: Nodo en slot %d no es válido o no es del tipo esperado." % i)
			continue
			
		if not slot_node.has_method("update_display"):
			printerr("InventoryUIController: El nodo Slot %d no tiene el método update_display: %s" % [i, slot_node])
			continue
			
		if slot_data:
			var item_data_resource = slot_data["item"]
			var quantity = slot_data["quantity"]
			slot_node.update_display(item_data_resource, quantity)
		else:
			slot_node.update_display(null, 0)
			
	print("InventoryUIController: update_display completado.")

# Manejar la entrada global para mostrar/ocultar el inventario
func _unhandled_input(event: InputEvent) -> void:
	# Usamos _unhandled_input para capturar la tecla incluso si otros nodos consumen inputs
	# Comprobar si se presionó la acción "toggle_inventory"
	if event.is_action_pressed("toggle_inventory"):
		print("Acción 'toggle_inventory' detectada!") # Para depuración
		# Invertir la visibilidad actual del panel de inventario
		self.visible = not self.visible
		# Marcar la entrada como manejada para que no active otras cosas (como el movimiento del jugador)
		get_viewport().set_input_as_handled()

		# Acciones opcionales al abrir/cerrar
		if self.visible:
			print("Inventario abierto (visible=true)") # Para depuración
		else:
			print("Inventario cerrado (visible=false)") # Para depuración
