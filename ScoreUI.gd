extends Control

@onready var score_label: Label = $Label

func _ready():
	GameManager.connect("score_changed", update_score)
	update_score(GameManager.total_score)

func update_score(new_score: int):
	score_label.text = "x" + str(new_score)

	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_label, "scale", Vector2(1, 1), 0.1)
