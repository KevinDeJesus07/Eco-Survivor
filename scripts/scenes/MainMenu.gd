extends Control


func _on_button_pressed() -> void:
	var path = "res://scenes/main/MainTestScene.tscn"
	Logger.info("MAIN_MENU", "Botón jugar presionado. cambiando a escena: " + str(path), self)
	var error = get_tree().change_scene_to_file(path)
	
	if error != OK:
		Logger.error("MAIN_MENU", "Fallo al cambiar a la escena '" + str(path) + "' Código de error: " + str(error), self)
