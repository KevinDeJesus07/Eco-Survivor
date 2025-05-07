extends Area2D

@export var item_data: ItemData

@onready var visual_placeholder: ColorRect = $VisualPlaceholder
@onready var item_texture_sprite: Sprite2D = $ItemTextureSprite

func _ready():
	if not is_instance_valid(item_data):
		printerr("ItemPickup [", name, "] no tiene ItemData asignado.")
		if visual_placeholder:
			visual_placeholder.visible = false
		if item_texture_sprite:
			item_texture_sprite.visible = false
		return
	
	body_entered.connect(_on_body_entered)
	print("ItemPickup listo en: ", global_position, " con ItemData: ", item_data.item_name if is_instance_valid(item_data) else "NINGUNO")
	update_visual()
	
func update_visual():
	if visual_placeholder:
		visual_placeholder.visible = false
	if item_texture_sprite:
		item_texture_sprite.visible = false
		
	if not is_instance_valid(item_data):
		return
		
	var item_texture_resource = item_data.texture
	if item_texture_resource:
		if item_texture_sprite:
			item_texture_sprite.texture = item_texture_resource
			item_texture_sprite.visible = true
			var max_size = 32.0
			var current_text_size = item_texture_resource.get_size()
			var scale_factor = max_size / max(current_text_size.x, current_text_size.y)
			if scale_factor < 1.0:
				item_texture_sprite.scale = Vector2(scale_factor, scale_factor)
			else:
				item_texture_sprite.scale = Vector2(1, 1)
		
			print("ItemPickup [", item_data.item_name, "]: Mostrando textura.")
		if visual_placeholder:
			visual_placeholder.visible = false
	
	elif visual_placeholder:
		visual_placeholder.color = item_data.placeholder_color
		visual_placeholder.visible = true
		if item_texture_sprite:
			item_texture_sprite.visible = false
		print("ItemPickup [", item_data.item_name, "]: Mostrando placeholder_color.")
	else:
		print("ItemPickup [", item_data.item_name, "]: No hay visual que mostrar (ni textura, ni placeholder).")

func _on_body_entered(body):
	if not is_instance_valid(item_data):
		print("Area de Item sin datos detectó entrada de: ", body.name)
		return
	print("Area de ", item_data.item_name if is_instance_valid(item_data) else "Item sin datos", " detectó entrada de: ", body.name)
		
	if body.is_in_group("Player"):
		print(body.name, " está en el grupo Player. Intentando recoger.")
		if InventoryManager:
			var remaining_quantity = InventoryManager.add_item(item_data, 1)
			if remaining_quantity == 0:
				print("Jugador recogió: ", item_data.item_name)
				queue_free()
			else:
				print("No se pudo recoger ", item_data.item_name, ". Inventario posiblemente lleno o el ítem no se pudo añadir.")
		else:
			printerr("ItemPickup: InventoryManager no encontrado!")
	else:
		print(body.name, " NO está en el grupo Player.")
