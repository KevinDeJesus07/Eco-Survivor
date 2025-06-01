extends Item
class_name HealItem

@export var heal_amount: int = 1

func apply_effect(body: Node) -> void:
	if body.has_method("heal"):
		body.heal(heal_amount)
