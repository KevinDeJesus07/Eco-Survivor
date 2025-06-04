extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	for boton in $PanelContainer.get_children():
		if boton is Button:
			boton.process_mode = Node.PROCESS_MODE_ALWAYS

	$PanelContainer/Continuar.pressed.connect(_on_continuar_pressed)
	$PanelContainer/Reiniciar.pressed.connect(_on_reiniciar_pressed)
	$PanelContainer/Salir.pressed.connect(_on_salir_pressed)


func resume():
	visible = false
	get_tree().paused = false
	#$AnimationPlayer.play_backwards("blur")

func pause():
	visible = true
	get_tree().paused = true
	#$AnimationPlayer.play("blur")
	
func _on_continuar_pressed() -> void:
	visible = false
	print("funciona continuar")
	resume()
	
func _on_reiniciar_pressed() -> void:
	print("funciona reiniciar")
	get_tree().paused = false
	
	get_tree().reload_current_scene()
	TimerLogic.reiniciar_completamente()
	
func _on_salir_pressed() -> void:
	print("funciona salir")
	get_tree().quit()
	

func _input(event):
	if event.is_action_pressed("escape"): 
		if get_tree().paused:
			resume()
		else:
			pause()
