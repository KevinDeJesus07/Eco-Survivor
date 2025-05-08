@tool
extends Resource

class_name ItemData # Permite usar 'ItemData' como tipo de variable

@export var item_name: String = "Unnamed Item"
@export var description: String = ""
@export var stack_size: int = 10
@export var placeholder_color: Color = Color.PURPLE
@export var texture: Texture2D

@export_group("Animación")
@export var is_animated: bool = false
@export var spritesheet: Texture2D = null
@export var h_frames: int = 1
@export var v_frames: int = 1
@export var animation_name: String = "default"
@export var animation_speed: float = 5.0
@export var animation_loop: bool = true

func _init(p_name := "Default", p_color := Color.PURPLE):
	item_name = p_name
	placeholder_color = p_color

func _to_string() -> String:
	return "ItemData(%s)" % item_name
