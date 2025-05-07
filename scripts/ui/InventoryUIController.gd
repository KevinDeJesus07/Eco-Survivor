extends PanelContainer

@onready var slot_grid: GridContainer = $MarginContainer/SlotGrid

const InventorySlotScene = preload("res://scenes/ui/InventorySlot.tscn")

@export var inventory_slots_count: int = 20

var is_dragging: bool = false
var dragged_item_data: ItemData = null
var dragged_item_quantity: int = 0
var original_slot_index: int = -1
var drag_preview_node: TextureRect

var ui_layer: CanvasLayer

func _ready() -> void:
	self.visible = false
	
	var potential_parent_canvas_layer = get_parent().get_parent()
	if potential_parent_canvas_layer is CanvasLayer:
		ui_layer = potential_parent_canvas_layer
		print("InventoryUIController: ui_layer asignado a: ", ui_layer)
	else:
		ui_layer = null # Si no es un CanvasLayer, ui_layer será null
		printerr("InventoryUIController: No se pudo encontrar el CanvasLayer padre (InventoryLayer) esperado en get_parent().get_parent().")
		if potential_parent_canvas_layer: # Si encontró algo, pero no era CanvasLayer
			printerr("  El nodo encontrado fue: ", potential_parent_canvas_layer, " de tipo: ", typeof(potential_parent_canvas_layer))
		else: # Si get_parent().get_parent() fue null
			printerr("  La jerarquía get_parent().get_parent() devolvió null.")
	
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
		
	drag_preview_node = TextureRect.new()
	drag_preview_node.mouse_filter = MOUSE_FILTER_IGNORE
	drag_preview_node.visible = false
	
	var preview_size: Vector2 = Vector2(50,50)
	
	drag_preview_node.size = preview_size
	drag_preview_node.custom_minimum_size = preview_size
	drag_preview_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	drag_preview_node.z_index = 100
	drag_preview_node.z_as_relative = true

func _process(delta: float) -> void:
	if is_dragging:
		if drag_preview_node and drag_preview_node.is_inside_tree():
			drag_preview_node.global_position = get_global_mouse_position() - (drag_preview_node.size / 2.0)
			
		if Input.is_action_just_released("ui_mouse_left_click"):
			print("InventoryUIController _process: DETECTADO 'ui_mouse_left_click' LIBERADO mientras se arrastra.")
			_handle_drop()

# Función para crear los slots visuales vacíos y añadirlos a la cuadrícula
func populate_grid() -> void:
	# Limpiar slots anteriores si esta función se llamara de nuevo (poco probable aquí)
	for child in slot_grid.get_children():
		child.queue_free()

	# Crear el número especificado de instancias de InventorySlot
	for i in range(inventory_slots_count):
		var slot_instance = InventorySlotScene.instantiate()
		
		if slot_instance.has_method("update_display"):
			slot_instance.slot_index = i
			
			if slot_instance.is_connected("item_drag_started", Callable(self, "_on_slot_item_drag_started")) == false:
				slot_instance.item_drag_started.connect(_on_slot_item_drag_started)
			else:
				print("Señal ya conectada o no existe para slot ", i)
		else:
			printerr("La instancia de slot no tiene em método 'update_display' o 'item_drag_started' no existe.")
		
		slot_grid.add_child(slot_instance)

func _on_slot_item_drag_started(slot_idx: int, item_data_clicked: ItemData, quantity_clicked: int):
	if is_dragging:
		return
		
	print("InventoryUIController: Iniciando arrastre desde slot: ", slot_idx)
	is_dragging = true
	original_slot_index = slot_idx
	dragged_item_data = item_data_clicked
	dragged_item_quantity = quantity_clicked
	
	var preview_as_texture_rect = drag_preview_node as TextureRect
	if not preview_as_texture_rect:
		printerr("Error Crítico: drag_preview_node no es un TextureRect. Verifica _ready() en InventoryUIController.")
		is_dragging = false # Cancelar el arrastre si el preview no es el tipo correcto
		return
		
	if dragged_item_data: # Si tenemos datos del ítem que se está arrastrando
		var item_actual_texture = dragged_item_data.texture # Accede directamente a la propiedad 'texture' de tu ItemData

		if item_actual_texture: # Si el ItemData tiene una textura asignada en su propiedad 'texture'
			preview_as_texture_rect.texture = item_actual_texture
			preview_as_texture_rect.modulate = Color.WHITE # Asegurar que no esté tintado por usos anteriores
			print("Drag preview: Usando item_data.texture.")
		else: 
			# No hay 'texture' asignada en ItemData, entonces usamos 'placeholder_color'.
			# Creamos una textura sobre la marcha con ese color.
			if preview_as_texture_rect.size.x <= 0 or preview_as_texture_rect.size.y <= 0:
				printerr("drag_preview_node tiene tamaño inválido (", preview_as_texture_rect.size, ") para crear imagen de color.")
				preview_as_texture_rect.texture = null # No se puede crear textura si el tamaño es inválido
			else:
				print("Drag preview: No hay item_data.texture. Creando textura desde placeholder_color: ", dragged_item_data.placeholder_color)
				var img = Image.create(int(preview_as_texture_rect.size.x), int(preview_as_texture_rect.size.y), false, Image.FORMAT_RGBA8)
				img.fill(dragged_item_data.placeholder_color) # Usa el placeholder_color del ItemData
				var tex = ImageTexture.create_from_image(img)
				preview_as_texture_rect.texture = tex
	else: 
		preview_as_texture_rect.texture = null
		print("Drag preview: dragged_item_data es null.")
	
	if ui_layer:
		if drag_preview_node.get_parent() != ui_layer:
			if drag_preview_node.get_parent() != null:
				drag_preview_node.get_parent().remove_child(drag_preview_node)
		ui_layer.add_child(drag_preview_node)
		print("InventoryUIController: drag_preview_node (re)añadido a ui_layer.")
	else:
		if drag_preview_node.get_parent() != self:
			if drag_preview_node.get_parent() != null:
				drag_preview_node.remove_child(drag_preview_node)
			add_child(drag_preview_node)
			printerr("InventoryUIController: ADVERTENCIA - ui_layer no es válido. drag_preview_node añadido a self.")
	
	drag_preview_node.visible = true
	
	print("drag_preview_node es: ", drag_preview_node)
	print("Tipo de drag_preview_node: ", typeof(drag_preview_node))
	print("drag_preview_node es Control?: ", drag_preview_node is Control)
	#print("drag_preview_node es ColorRect?: ", drag_preview_node is ColorRect)
	if drag_preview_node:
		print("Parent de drag_preview_node: ", drag_preview_node.get_parent())
		print("drag_preview_node está en el árbol?: ", drag_preview_node.is_inside_tree())
	
	#drag_preview_node.raise()
	
	var source_slot_node = slot_grid.get_child(original_slot_index)
	if source_slot_node and source_slot_node.has_method("set_as_drag_source_visuals"):
		source_slot_node.set_as_drag_source_visuals(true)

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
			print("InventoryUIController: Pasando a slot_node [", i, "] update_display() con ItemData: ", item_data_resource, " (Nombre: ", item_data_resource.item_name if item_data_resource else "NULL", "), Cantidad: ", quantity)
			slot_node.update_display(item_data_resource, quantity)
		else:
			print("InventoryUIController: Pasando a slot_node [", i, "] update_display() con NULL (slot vacío)")
			slot_node.update_display(null, 0)
			
	print("InventoryUIController: update_display completado.")

# Manejar la entrada global para mostrar/ocultar el inventario
func _unhandled_input(event: InputEvent) -> void:
	if is_dragging:
		print("IUController _unhandled_input (is_dragging=true): Evento recibido: ", event)
		if event is InputEventMouseButton:
			print("  Es InputEventMouseButton: button_index=", event.button_index, ", pressed=", event.pressed)
	
	# Usamos _unhandled_input para capturar la tecla incluso si otros nodos consumen inputs
	# Comprobar si se presionó la acción "toggle_inventory"
	if event.is_action_pressed("toggle_inventory"):
		print("Acción 'toggle_inventory' detectada!") # Para depuración
		if self.visible and is_dragging:
			print("Inventario visible y arrastrando, cancelando drag antes de cerrar.")
			_cancel_drag_operation()
		# Invertir la visibilidad actual del panel de inventario
		self.visible = not self.visible
		# Marcar la entrada como manejada para que no active otras cosas (como el movimiento del jugador)
		get_viewport().set_input_as_handled()

		# Acciones opcionales al abrir/cerrar
		if self.visible:
			print("Inventario abierto (visible=true)") # Para depuración
		else:
			print("Inventario cerrado (visible=false)") # Para depuración
			if is_dragging:
				_cancel_drag_operation()

func _handle_drop() -> void:
	if not is_dragging:
		return
		
	print("InventoryUIController: Manejando _handle_drop().")
	
	drag_preview_node.visible = false
	
	if original_slot_index >= 0 and original_slot_index < slot_grid.get_children().size():
		var source_slot_node = slot_grid.get_child(original_slot_index)
		if source_slot_node and source_slot_node.has_method("set_as_drag_source_visuals"):
			source_slot_node.set_as_drag_source_visuals(false)
			
	var target_slot_index: int = -1
	var mouse_pos = get_global_mouse_position()
	
	for i in range(slot_grid.get_children().size()):
		var slot_node_control: Control = slot_grid.get_child(i) as Control
		if slot_node_control and slot_node_control.get_global_rect().has_point(mouse_pos):
			target_slot_index = i
			break
			
	var item_moved_successfully = false
	if target_slot_index != -1 and target_slot_index != original_slot_index:
		print("InventoryUIController: Ítem soltado en slot [", target_slot_index, "] desde slot [", original_slot_index, "]")
		if InventoryManager:
			InventoryManager.move_or_swap_item_in_slots(original_slot_index, target_slot_index)
			item_moved_successfully = true
		elif target_slot_index == original_slot_index:
			print("InventoryUIController: Ítem soltado fuera de un slot válido. No hay cambios en datos.")
		else:
			print("InventoryUIController: Ítem soltado fuera de un slot válido. No hay cambios en datos.")
			
		is_dragging = false
		
func _cancel_drag_operation() -> void:
	if not is_dragging:
		return
		
	print("InventoryUIController: Cancelando operación de arrastre.")
	is_dragging = false
	if drag_preview_node:
		drag_preview_node.visible = false
		
	if original_slot_index != -1 and original_slot_index < slot_grid.get_children().size():
		var source_slot_node = slot_grid.get_child(original_slot_index)
		if source_slot_node and source_slot_node.has_method("set_as_drag_source_visuals"):
			source_slot_node.set_as_drag_source_visuals(false)
	
	dragged_item_data = null
	dragged_item_quantity = 0
	original_slot_index = -1
