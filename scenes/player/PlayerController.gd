extends CharacterBody2D

@export var speed: float = 300.0 # píxeles por segundo

@onready var visual_sprite: Sprite2D = $Sprite2D
@onready var placeholder_color: ColorRect = $VisualPlaceholder

func _physics_process(delta: float) -> void:
	# Obtener el vector de dirección
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction != Vector2.ZERO:
		velocity = input_direction.normalized() * speed
	else:
		velocity = Vector2.ZERO
		
	# Mover el personaje y manejar colisiones
	move_and_slide()
	
func _ready():
	Logger.error("PRUEBA", "Mensaje de error", self)
	Logger.warn("PRUEBA", "Mensaje de prueba", self)
	Logger.info("PRUEBA", "Mensaje de info", self)
	Logger.debug("PRUEBA", "Mensaje de debug", self)
	update_visuals()
	
func update_visuals():
	print("--- UPDATE VISUALS para: '", name, "' ---")
	
	if not visual_sprite:
		printerr("Player.gd: Nodo VisualSprite no encontrado. Verifica la ruta.")
		if placeholder_color:
			placeholder_color.visible = false
		return
	
	if not placeholder_color:
		printerr("Player.gd: Nodo PlaceholderColor no encontrado. Verifica la ruta.")
		if visual_sprite.texture:
			visual_sprite.visible = true
		else:
			visual_sprite.visible = false
		return
		
	if visual_sprite.texture:
		visual_sprite.visible = true
		placeholder_color.visible = false
		print("Player: Mostrando textura del sprite.")
	else:
		visual_sprite.visible = false
		placeholder_color.visible = true
		print("Player: No hay textura en sprite, mostrando color de respaldo.")
		
	print("  Estado final: visual_sprite_node.visible=", visual_sprite.visible, ", placeholder_color_node.visible=", placeholder_color.visible)
	print("--- FIN UPDATE VISUALS para: '", name, "' ---")
