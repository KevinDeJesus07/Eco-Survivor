extends Area2D

@export var item_data: ItemData

@onready var visual_placeholder: ColorRect = $VisualPlaceholder

func _ready():
	if not item_data:
		printerr("ItemPickup en ", global_position, " no tiene asignado un ItemData!")
		return
	else:
		if visual_placeholder and "placeholder_color" in item_data:
			visual_placeholder.color = item_data.placeholder_color
		elif visual_placeholder:
			visual_placeholder.color = Color.MAGENTA
	
	body_entered.connect(_on_body_entered)
	print("ItemPickup listo en: ", global_position, " con ItemData: ", item_data.item_name if is_instance_valid(item_data) else "NINGUNO")
	
func _on_body_entered(body):
	print("Area de ", item_data.item_name if is_instance_valid(item_data) else "Item sin datos", " detectó entrada de: ", body.name)
	if not item_data:
		return
		
	if body.is_in_group("Player"):
		print(body.name, " está en el grupo Player. Intentando recoger.")
		print("Jugador recogió: ", item_data.item_name)
		if InventoryManager:
			InventoryManager.add_item(item_data, 1)
		queue_free()
	else:
		print(body.name, " NO está en el grupo Player.")
