extends Area2D

@export var item_data: ItemData

@onready var visual_placeholder: ColorRect = $VisualPlaceholder
@onready var item_texture_sprite: Sprite2D = $ItemTextureSprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

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
	if animated_sprite:
		animated_sprite.visible = false
	
	if not is_instance_valid(item_data):
		return
	
	if item_data.is_animated and item_data.spritesheet and animated_sprite:
		var sprite_frames = animated_sprite.sprite_frames
		if not sprite_frames:
			sprite_frames = SpriteFrames.new()
			animated_sprite.sprite_frames = sprite_frames
		
		if sprite_frames.has_animation(item_data.animation_name):
			sprite_frames.clear(item_data.animation_name)
		
		sprite_frames.add_animation(item_data.animation_name)
		sprite_frames.set_animation_loop(item_data.animation_name, item_data.animation_loop)
		sprite_frames.set_animation_speed(item_data.animation_name, item_data.animation_speed)
		
		var tex = item_data.spritesheet
		var h_frames = item_data.h_frames
		var v_frames = item_data.v_frames
		
		if h_frames <= 0:
			h_frames = 1
		if v_frames <= 0:
			v_frames = 1
			
		var frame_width = tex.get_width() / h_frames
		var frame_height = tex.get_height() / v_frames
		
		for y in range(v_frames):
			for x in range(h_frames):
				pass
				#sprite_frames.add_frame(item_data.animation_name, tex, 1.0, Rect2(x * frame_width, y * frame_height, frame_width, frame_height))
		
		animated_sprite
		
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
