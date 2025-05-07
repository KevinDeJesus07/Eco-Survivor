extends CharacterBody2D

@onready var visual_sprite: Sprite2D = $Sprite2D
@onready var placeholder_color: ColorRect = $VisualPlaceholder

func _ready():
	update_visuals()
	
func update_visuals():
	if not visual_sprite:
		printerr("Player.gd: Nodo VisualSprite no encontrado. Verifica la ruta.")
		if placeholder_color:
			placeholder_color.visible = false
		return
	
	if not placeholder_color:
		printerr("Player.gd: Nodo PlaceholderColor no encontrado. Verifica la ruta.")
		if visual_sprite.texture:
			visual_sprite.visible = true
		else:
			visual_sprite.visible = false
		return
		
	if visual_sprite.texture:
		visual_sprite.visible = true
		placeholder_color.visible = false
		print("Player: Mostrando textura del sprite.")
	else:
		visual_sprite.visible = false
		placeholder_color.visible = true
		print("Player: No hay textura en sprite, mostrando color de respaldo.")
