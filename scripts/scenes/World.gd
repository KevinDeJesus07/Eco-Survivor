extends Node2D

func _ready():
	GameManager.reset_difficulty()
	TimerLogic.iniciar_temporizador()
	var timer_ui = preload("res://scenes/ui/TimerUI.tscn").instantiate()
	$TimerUILayer/TimerContainer.add_child(timer_ui)
