extends Panel

signal item_drag_started(slot_index: int, item_data: ItemData, quantity: int)

@onready var color_display_node: ColorRect = $ColorDisplay
@onready var icon_display_node: TextureRect = $IconDisplay
@onready var quantity_label: Label = $QuantityLabel

var current_item_data: ItemData = null
var current_quantity: int = 0
var slot_index: int = -1 # El índice de este slot en la cuadricula

var normal_bg_color: Color = Color(0.2, 0.2, 0.2, 0.7)
var hover_bg_color: Color = Color(0.35, 0.35, 0.35, 0.7)

func _ready():
	color_display_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_display_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	var initial_style_box = get_theme_stylebox("panel")
	if initial_style_box is StyleBoxFlat:
		normal_bg_color = initial_style_box.bg_color
	
	self.mouse_filter = Control.MOUSE_FILTER_PASS
	
	if icon_display_node:
		var slot_size: Vector2 = Vector2(50, 50)
		
		icon_display_node.custom_minimum_size = slot_size
		icon_display_node.size = slot_size
		
		icon_display_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_display_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	update_display(null, 0)

func _on_mouse_entered():
	var style_box_override = get_theme_stylebox("panel").duplicate(true)
	if style_box_override is StyleBoxFlat:
		style_box_override.bg_color = hover_bg_color
		add_theme_stylebox_override("panel", style_box_override)
		
func _on_mouse_exited():
	var style_box_override = get_theme_stylebox("panel").duplicate(true)
	if style_box_override is StyleBoxFlat:
		style_box_override.bg_color = normal_bg_color
		add_theme_stylebox_override("panel", style_box_override)
		
func update_display(item_data: ItemData = null, quantity: int = 0) -> void:
	current_item_data = item_data
	current_quantity = quantity

	icon_display_node.visible = false
	color_display_node.visible = false
	quantity_label.visible = false

	if current_item_data and current_quantity > 0:
		var item_texture = current_item_data.get("texture")
		
		if item_texture:
			icon_display_node.texture = item_texture
			icon_display_node.visible = true
		else:
			color_display_node.color = current_item_data.placeholder_color
			color_display_node.visible = true
		
		#item_visual.color = current_item_data.placeholder_color

		if current_quantity > 1: # >= 1 si queremos mostrar el '1'
			quantity_label.text = str(current_quantity)
			quantity_label.visible = true
		else:
			quantity_label.text = ""
			quantity_label.visible = false
	else:
		color_display_node.visible = false
		color_display_node.visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("Slot [", slot_index, "] _gui_input: Recibido InputEventMouseButton. Botón: ", event.button_index, ", Presionado: ", event.pressed)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("Slot [", slot_index, "] _gui_input: (Pressed) Clic detectado.")
				print("  (Pressed) Valor de current_item_data: ", current_item_data)
				if current_item_data:
					print("  (Pressed) Nombre del current_item_data (si existe): ", current_item_data.item_name)
				print("  (Pressed) Valor de current_quantity: ", current_quantity)
		
				if current_item_data and current_quantity > 0:
					print("Slot [", slot_index, "]: (Pressed) Clic para iniciar arrastre. Ítem: ", current_item_data.item_name)
					item_drag_started.emit(slot_index, current_item_data, current_quantity)
				else:
					print("Slot [", slot_index, "]: (Pressed) Clic en slot vacío")
			else:
				print("Slot [", slot_index, "] _gui_input: BOTÓN IZQUIERDO LIBERADO SOBRE ESTE SLOT.")
	else:
		print("Slot [", slot_index, "] _gui_input: Evento recibido NO es InputEventMouseButton: ", event)
			
func set_as_drag_source_visuals(is_source: bool):
	var alpha_value = 0.3 if is_source else 1.0
	
	if icon_display_node.visible:
		icon_display_node.modulate.a = alpha_value
	elif color_display_node.visible:
		color_display_node.modulate.a = alpha_value
	
	if (icon_display_node.visible or color_display_node.visible) and quantity_label:
		quantity_label.modulate.a = alpha_value
	elif not is_source and quantity_label: # Al restaurar, asegurar que la label vuelva a ser opaca
		quantity_label.modulate.a = 1.0
