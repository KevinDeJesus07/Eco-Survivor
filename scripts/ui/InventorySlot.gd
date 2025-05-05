extends Panel

@onready var item_visual: ColorRect = $ItemVisual
@onready var quantity_label: Label = $QuantityLabel

var current_item_data: ItemData = null
var current_quantity: int = 0

func _ready():
	item_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	update_display(null, 0)

func update_display(item_data: ItemData = null, quantity: int = 0) -> void:
	current_item_data = item_data
	current_quantity = quantity  # ← este es el fix de línea 16

	if current_item_data and current_quantity > 0:
		item_visual.color = current_item_data.placeholder_color
		item_visual.visible = true

		if current_quantity > 1:
			quantity_label.text = str(current_quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	else:
		item_visual.visible = false
		quantity_label.visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_item_data:
			print("Clic en slot con ítem: ", current_item_data.item_name)
		else:
			print("Clic en slot vacío")
