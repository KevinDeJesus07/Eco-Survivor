extends Resource

class_name ItemData # Permite usar 'ItemData' como tipo de variable

@export var item_name: String = "Unnamed Item"
@export var description: String = ""
@export var stack_size: int = 10
@export var placeholder_color: Color = Color.PURPLE
@export var texture: Texture2D

func _init(p_name := "Default", p_color := Color.PURPLE):
	item_name = p_name
	placeholder_color = p_color
