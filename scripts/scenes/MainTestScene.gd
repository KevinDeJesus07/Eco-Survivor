extends Node2D

@onready var ui_container = $InventoryLayer

func _ready():
	var timer_node = TimerUIManager
	if not is_instance_valid(timer_node):
		return
		
	timer_node.reparent(ui_container)
	TimerUIManager.iniciar_temporizador()
