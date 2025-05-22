extends Panel

signal item_drag_started(slot_index: int, item: Item, quantity: int)

@onready var color: ColorRect = $ColorDisplay
@onready var icon: TextureRect = $IconDisplay
@onready var quantity_label: Label = $QuantityLabel

var curr_item: Item = null
var curr_quantity: int = 0
var slot_index: int = -1 # El índice de este slot en la cuadricula

var normal_bg_color: Color = Color(0.2, 0.2, 0.2, 0.7)
var hover_bg_color: Color = Color(0.35, 0.35, 0.35, 0.7)

func _ready():
	# Conectar señales de hover
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Obtener color normal del tema
	var initial_style_box = get_theme_stylebox("panel")
	if initial_style_box is StyleBoxFlat:
		normal_bg_color = initial_style_box.bg_color
	
	self.mouse_filter = Control.MOUSE_FILTER_PASS
	
	if icon:
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
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
		
func update_display(item: Item = null, quantity: int = 0) -> void:
	curr_item = item
	curr_quantity = quantity

	if is_instance_valid(icon):
		icon.visible = false
	if is_instance_valid(color):
		color.visible = false
	if is_instance_valid(quantity_label):
		quantity_label.visible = false

	if curr_item and curr_quantity > 0:
		var item_icon = curr_item.icono
		
		if item_icon:
			if is_instance_valid(icon):
				icon.texture = item_icon
				icon.visible = true
			if is_instance_valid(color):
				color.visible = false
		elif is_instance_valid(color):
			color.color = curr_item.color
			color.visible = true
			if is_instance_valid(icon):
				icon.visible = false
				
		if is_instance_valid(quantity_label):
			if curr_quantity > 1:
				quantity_label.text = str(curr_quantity)
				quantity_label.visible = true
			else:
				quantity_label.text = ""
				quantity_label.visible = false

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		Logger.debug("INV_SLOT", "'event' no es un 'InputEventMouseButton'")
		return
	
	if event.button_index != MOUSE_BUTTON_LEFT:
		Logger.debug("INV_SLOT", "No se presiono el clic izquierdo")
		return
		
	if not event.pressed:
		Logger.debug("INV_SLOT", "Botón de clic izquierdo soltado", self)
		return
		
	if not curr_item:
		Logger.debug("INV_SLOT", "Clic en slot vacio", self)
		return
		
	if not curr_quantity > 0:
		Logger.warn("INV_SLOT", "Item presente pero cantidad <= 0", self)
		return
	
	Logger.info("INV_SLOT", "Iniciando arrastre para: " + str(curr_item.name), self)
	item_drag_started.emit(slot_index, curr_item, curr_quantity)

func set_as_drag_source_visuals(is_source: bool):
	var alpha = 0.3 if is_source else 1.0
	
	if not is_instance_valid(icon):
		Logger.error("INV_SLOT", "'icon' no es válido para slot", self)
		return
	
	if not is_instance_valid(color):
		Logger.error("INV_SLOT", "'color' no es válido para slot", self)
		return
		
	if not is_instance_valid(quantity_label):
		Logger.error("INV_SLOT", "'quantity_label' no es válido para slot", self)
		return
	
	icon.modulate.a = alpha
	color.modulate.a = alpha
	quantity_label.modulate.a = alpha
