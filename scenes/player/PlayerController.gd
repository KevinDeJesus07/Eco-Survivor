extends CharacterBody2D

@export var speed: float = 150.0 # píxeles por segundo

func _physics_process(delta: float) -> void:
	# Obtener el vector de dirección
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction != Vector2.ZERO:
		velocity = input_direction.normalized() * speed
	else:
		velocity = Vector2.ZERO
		
	# Mover el personaje y manejar colisiones
	move_and_slide()
