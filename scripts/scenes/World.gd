extends Node2D

@onready var menu = $PauseLayer/CenterContainer/PauseMenu

func _ready():
	GameManager.reset_difficulty()
	TimerLogic.iniciar_temporizador()
	var timer_ui = preload("res://scenes/ui/TimerUI.tscn").instantiate()
	$TimerUILayer/TimerContainer.add_child(timer_ui)
	menu.visible = false
