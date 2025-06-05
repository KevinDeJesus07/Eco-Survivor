extends Item
class_name TrashItem

@export var score_amount: int = 1

func apply_effect(body: Node) -> void:
	if body.has_method("recycle"):
		body.recycle(score_amount)
