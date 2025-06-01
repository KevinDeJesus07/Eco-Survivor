@tool
extends Resource
class_name Item

@export_group("Information")
@export var name: String = "Unnamed item"
@export var desc: String = ""
@export var is_stacked: bool = true
@export var stack_max: int = 10

@export_group("Visuals")
@export var icono: Texture2D = null
@export var color: Color = Color.PURPLE

func apply_effect(body: Node) -> void:
	pass

func _to_string() -> String:
	return "Item(%s)" % name
