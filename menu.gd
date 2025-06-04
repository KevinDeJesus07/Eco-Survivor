extends Control

func _ready():

	# Confirmación visual
	print("[Menu] Listo")

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")

func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	


func testEsc():
	if Input.is_action_just_pressed("escape") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("escape") and get_tree().paused:
		resume()
		
	
	
func _on_continuar_pressed() -> void:
	visible = false
	resume()
	print("funciona1")



func _on_reiniciar_pressed() -> void:
	
	get_tree().reload_current_scene()
	print("funciona2")


func _on_salir_pressed() -> void:
	
	get_tree().quit()
	print("funciona3")

func _process(_delta):
	testEsc()
