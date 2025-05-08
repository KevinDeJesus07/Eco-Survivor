extends PanelContainer

const LOG_CAT = "INVENTORY_UI"
const SLOT_SCENE = preload("res://scenes/ui/InventorySlot.tscn")

@export var slot_count: int = 20

@onready var slot_grid: GridContainer = $MarginContainer/SlotGrid

var is_dragging: bool = false
var drag_item: Item = null
var drag_qty: int = 0
var origin_idx: int = -1
var drag_preview: TextureRect
var ignore_release: bool = false

var ui_layer: CanvasLayer

func _ready():
	self.visible = false
	
	_setup_ui_layer()
	_populate_grid()
	_connect_to_inventory_manager()
	_create_drag_preview()
	
func _process(delta):
	if is_dragging:
		if drag_preview and drag_preview.is_inside_tree():
			drag_preview.global_position = get_global_mouse_position() - (drag_preview.size / 2.0)
			
		if Input.is_action_just_released("ui_mouse_left_click"):
			Logger.debug(LOG_CAT, "PROCESS: Detectado release de 'ui_mouse_left_click' mientras is_dragging=true.", self)
			_handle_drop()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		Logger.debug(LOG_CAT, "Input: Acción 'toggle_inventory' detectada.", self)
		
		if self.visible and is_dragging:
			Logger.info(LOG_CAT, "Input: Intento de cerrar UI mientras se arrastra. Cancelando drag.", self)
			_cancel_drag()
			get_viewport().set_input_as_handled()
			return
			
		self.visible = not self.visible
		get_viewport().set_input_as_handled()
		
		if self.visible:
			Logger.info(LOG_CAT, "Input: Inventario abierto.", self)
		else:
			Logger.info(LOG_CAT, "Input: Inventario cerrado.", self)
			if is_dragging:
				_cancel_drag()
		
func _setup_ui_layer():
	var potential_layer = get_parent().get_parent()
	if potential_layer is CanvasLayer:
		ui_layer = potential_layer
		Logger.info("", "", self)
	else:
		ui_layer = null
		Logger.error(LOG_CAT, "ui_layer asignado a: " + str(ui_layer), self)
		if potential_layer:
			Logger.error(LOG_CAT, "  Nodo encontrado fue: " + str(potential_layer), self)

func _populate_grid():
	for child in slot_grid.get_children():
		child.queue_free()
		
	for i in range(slot_count):
		var slot_node = SLOT_SCENE.instantiate() as Panel
		if slot_node and slot_node.has_method("update_display"):
			slot_node.slot_index = i
			if not slot_node.is_connected("item_drag_started", Callable(self, "_on_slot_drag_start")):
				slot_node.item_drag_started.connect(_on_slot_drag_start)
		else:
			Logger.error(LOG_CAT, "Instancia de slot InvSlot.gd inválida o sin método/señal: indice " + str(i), self)
		
		slot_grid.add_child(slot_node)
	
	Logger.debug(LOG_CAT, "Grid poblado con " + str(slot_count) + " slots.", self)
	
func _connect_to_inventory_manager():
	if InventoryManager:
		if not InventoryManager.is_connected("inventory_changed", Callable(self, "update_display")):
			InventoryManager.inventory_changed.connect(update_display)
			
		update_display()
		Logger.info(LOG_CAT, "Conectado a InventoryManager.inventory_changed.", self)
	else:
		Logger.error(LOG_CAT, "¡InventoryManager (Autoload) no encontrado!", self)

func _create_drag_preview():
	drag_preview = TextureRect.new() 
	drag_preview.mouse_filter = MOUSE_FILTER_IGNORE
	drag_preview.visible = false
	var preview_size = Vector2(50, 50) # Tamaño deseado 
	drag_preview.custom_minimum_size = preview_size 
	drag_preview.size = preview_size                 
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE 
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED 
	drag_preview.z_index = 100 
	drag_preview.z_as_relative = true
	# Añadir al ui_layer (o self como fallback)
	if ui_layer:
		ui_layer.add_child(drag_preview)
	else:
		add_child(drag_preview)
		Logger.warn(LOG_CAT, "ui_layer no válido. drag_preview añadido a self (tamaño podría ser incorrecto).", self)

# ------
func update_display():
	# Guard Clause: Salir si el InventoryManager no está disponible
	if not InventoryManager:
		Logger.error(LOG_CAT, "InventoryManager no disponible en update_display.", self)
		return

	var inv_data: Array = InventoryManager.get_slots() # Usa tu función get_slots()
	var ui_slots: Array = slot_grid.get_children()
	
	# Verificar discrepancia (opcional, pero útil)
	if inv_data.size() != ui_slots.size():
		Logger.warn(LOG_CAT, "Discrepancia: slots de datos(%d) vs slots UI(%d)" % [inv_data.size(), ui_slots.size()], self)

	var num_to_update = min(inv_data.size(), ui_slots.size())
	# Logger.debug(LOG_CAT, "Actualizando " + str(num_to_update) + " slots.", self) # Log opcional

	for i in range(num_to_update):
		var item_data_in_slot = inv_data[i] # Puede ser null o {"item": Item, "quantity": int}
		var slot_node = ui_slots[i] as Panel # Castear a Panel (o al tipo raíz de tu slot)
		
		# Guard Clause para nodo inválido o sin método necesario
		if not slot_node or not slot_node.has_method("update_display"):
			# Logger.error(LOG_CAT, "Nodo de slot [" + str(i) + "] inválido o sin update_display.", self) # Log opcional
			continue # Saltar al siguiente slot

		if item_data_in_slot:
			var item_resource = item_data_in_slot["item"] # Tipo Item
			var quantity = item_data_in_slot["quantity"]
			# Logger.debug(LOG_CAT, "Update slot [" + str(i) + "] con Item: " + str(item_resource.name) + ", Qty: " + str(quantity), self) # Log opcional
			slot_node.update_display(item_resource, quantity) # Pasa Item
		else:
			# Logger.debug(LOG_CAT, "Update slot [" + str(i) + "] a vacío.", self) # Log opcional
			slot_node.update_display(null, 0)
			
	# Logger.debug(LOG_CAT, "update_display completado.", self) # Log opcional

# Llamado por la señal 'item_drag_started' desde InvSlot.gd
func _on_slot_drag_start(slot_idx: int, item: Item, quantity: int): # Nombre y params actualizados
	if is_dragging: return # Evitar iniciar un drag si ya hay uno
		
	Logger.info(LOG_CAT, "Iniciando arrastre desde slot: " + str(slot_idx) + " Item: " + item.name, self)
	is_dragging = true
	origin_idx = slot_idx
	drag_item = item 
	drag_qty = quantity
	ignore_release = true 
	
	var preview_tex_rect = drag_preview as TextureRect
	if not preview_tex_rect:
		Logger.error(LOG_CAT, "drag_preview no es TextureRect!", self)
		is_dragging = false; return
		
	# Configurar apariencia del preview
	if drag_item: 
		var item_ui_icon = drag_item.icono 
		if item_ui_icon: 
			preview_tex_rect.texture = item_ui_icon
			preview_tex_rect.modulate = Color.WHITE 
		else: # Crear textura de color
			if preview_tex_rect.size.x > 0 and preview_tex_rect.size.y > 0:
				var img = Image.create(int(preview_tex_rect.size.x), int(preview_tex_rect.size.y), false, Image.FORMAT_RGBA8)
				img.fill(drag_item.color) 
				var tex = ImageTexture.create_from_image(img)
				preview_tex_rect.texture = tex
			else: preview_tex_rect.texture = null
	else: 
		preview_tex_rect.texture = null

	# Asegurar que esté en el árbol y visible
	# (La lógica de re-parenting se mantiene igual que antes, era robusta)
	if ui_layer and drag_preview.get_parent() != ui_layer:
		var current_parent = drag_preview.get_parent()
		if current_parent: current_parent.remove_child(drag_preview)
		ui_layer.add_child(drag_preview)
	elif not ui_layer and drag_preview.get_parent() != self: 
		var current_parent = drag_preview.get_parent()
		if current_parent: current_parent.remove_child(drag_preview)
		add_child(drag_preview)

	drag_preview.visible = true 
	
	# Atenuar slot origen
	var source_slot_node = slot_grid.get_child(origin_idx)
	if source_slot_node and source_slot_node.has_method("set_as_drag_source_visuals"):
		source_slot_node.set_as_drag_source_visuals(true)

# Llamado desde _process al detectar liberación del botón izquierdo
func _handle_drop():
	Logger.debug(LOG_CAT, "_handle_drop() llamado.", self)
	if not is_dragging: return # Salir si no estábamos arrastrando
		
	# Ocultar preview y restaurar slot origen (antes de llamar al manager)
	if drag_preview: drag_preview.visible = false
	if origin_idx >= 0 and origin_idx < slot_grid.get_children().size():
		var source_node = slot_grid.get_child(origin_idx)
		if source_node and source_node.has_method("set_as_drag_source_visuals"):
			source_node.set_as_drag_source_visuals(false)
			
	# Encontrar slot destino
	var target_idx: int = -1
	var mouse_pos = get_global_mouse_position()
	for i in range(slot_grid.get_children().size()):
		var slot_node = slot_grid.get_child(i) as Control
		if slot_node and slot_node.get_global_rect().has_point(mouse_pos):
			target_idx = i
			break
			
	# Intentar mover/intercambiar en el InventoryManager
	if target_idx != -1 and target_idx != origin_idx:
		Logger.info(LOG_CAT, "Item soltado en slot [" + str(target_idx) + "] desde [" + str(origin_idx) + "].", self)
		if InventoryManager:
			InventoryManager.move_or_swap_item_in_slots(origin_idx, target_idx)
		else:
			Logger.error(LOG_CAT, "InventoryManager no encontrado en _handle_drop.", self)
	elif target_idx == origin_idx:
		Logger.debug(LOG_CAT, "Item soltado en el mismo slot de origen.", self)
	else: # target_idx == -1
		Logger.debug(LOG_CAT, "Item soltado fuera de un slot válido.", self)
			
	# Resetear estado de arrastre SIEMPRE al final
	is_dragging = false 
	# No necesitamos limpiar drag_item o origin_idx aquí, se sobreescribirán
	# la próxima vez que inicie un arrastre.

# Llamado si se cierra inventario mientras se arrastra o se libera botón no-izquierdo
func _cancel_drag(): # Nombre acortado
	if not is_dragging: return
		
	Logger.info(LOG_CAT, "Cancelando operación de arrastre.", self)
	is_dragging = false
	if drag_preview: drag_preview.visible = false
		
	if origin_idx != -1 and origin_idx < slot_grid.get_children().size():
		var source_node = slot_grid.get_child(origin_idx)
		if source_node and source_node.has_method("set_as_drag_source_visuals"):
			source_node.set_as_drag_source_visuals(false)
	
	# Resetear variables por si acaso
	drag_item = null
	drag_qty = 0
	origin_idx = -1
