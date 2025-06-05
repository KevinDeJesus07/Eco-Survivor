extends Node2D

@onready var name_input: LineEdit = $CanvasLayer/VBoxContainer/NameContainer/NameInput
@onready var male_button: Button = $CanvasLayer/VBoxContainer/GenderContainer/MaleButton
@onready var female_button: Button = $CanvasLayer/VBoxContainer/GenderContainer/FemaleButton
@onready var male_preview: AnimatedSprite2D = $CanvasLayer/VBoxContainer/PreviewContainer/MalePreview
@onready var female_preview: AnimatedSprite2D = $CanvasLayer/VBoxContainer/PreviewContainer/FemalePreview
@onready var error_label: Label = $CanvasLayer/VBoxContainer/ErrorLabel
@onready var play_button: Button = $CanvasLayer/VBoxContainer/PlayButton

var selected_gender: String = "male"

func _ready():
	# Cargar datos guardados si existen
	#GameManager.load_data()
	
	# Configurar estado inicial
	name_input.text = ""
	selected_gender = "male"
	
	# Actualizar vista
	update_gender_selection()
	update_previews()
	
	# Conectar señales
	male_button.pressed.connect(_on_male_pressed)
	female_button.pressed.connect(_on_female_pressed)
	play_button.pressed.connect(_on_play_pressed)
	name_input.text_changed.connect(_on_name_changed)
	
	# Iniciar animaciones
	start_animations()

func start_animations():
	# Para masculino: intentar reproducir "idle_down"
	if male_preview.sprite_frames != null and male_preview.sprite_frames.has_animation("idle_down"):
		male_preview.play("idle_down")
	else:
		push_warning("No se encontró la animación 'idle_down' para male_preview")
	
	# Para femenino: intentar reproducir "idle_down"
	if female_preview.sprite_frames != null and female_preview.sprite_frames.has_animation("idle_down"):
		female_preview.play("idle_down")
	else:
		push_warning("No se encontró la animación 'idle_down' para female_preview")

func _on_name_changed(new_text: String):
	# Limpiar mensajes de error al escribir
	error_label.text = ""
	error_label.visible = false

func _on_male_pressed():
	selected_gender = "male"
	update_gender_selection()
	update_previews()

func _on_female_pressed():
	selected_gender = "female"
	update_gender_selection()
	update_previews()

func update_gender_selection():
	# Resaltar el botón seleccionado
	male_button.modulate = Color(1, 1, 1, 0.5) if selected_gender != "male" else Color(1, 1, 1, 1)
	female_button.modulate = Color(1, 1, 1, 0.5) if selected_gender != "female" else Color(1, 1, 1, 1)

func update_previews():
	# Resaltar preview seleccionado
	male_preview.modulate = Color(1, 1, 1, 0.5) if selected_gender != "male" else Color(1, 1, 1, 1)
	female_preview.modulate = Color(1, 1, 1, 0.5) if selected_gender != "female" else Color(1, 1, 1, 1)
	
	# Asegurarse de que las animaciones siguen reproduciéndose
	if male_preview.animation == "":
		start_animations()

func _on_play_pressed():
	# Validar nombre
	var player_name = name_input.text.strip_edges()
	
	if player_name.length() < 3:
		error_label.text = "¡El nombre debe tener al menos 3 caracteres!"
		error_label.visible = true
		return
	
	if player_name.length() > 16:
		error_label.text = "¡El nombre es demasiado largo! (max 16)"
		error_label.visible = true
		return
	
	# Guardar selección
	GameManager.player_name = player_name
	GameManager.player_gender = selected_gender
	GameManager.save_data()
	
	# Cambiar a la escena principal del juego
	get_tree().change_scene_to_file("res://scenes/main/World.tscn")
