extends BaseEntity

@onready var visual_sprite: Sprite2D = $Sprite2D
@onready var placeholder: ColorRect = $VisualPlaceholder

func _ready():
	super._ready() 

	can_patrol = false 
	
	if visual_sprite:
		visual_sprite.visible = true
		placeholder.visible = false

	Logger.info(LOG_CAT, "'%s' (Player) listo y controlado por input." % name, self)



func _state_idle(delta: float):
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction != Vector2.ZERO:
		velocity = input_direction.normalized() * speed 
	else:
		velocity = Vector2.ZERO
	
	if is_instance_valid(visual_sprite):
		if input_direction.x < 0:
			visual_sprite.flip_h = true
		elif input_direction.x > 0:
			visual_sprite.flip_h = false

func _state_patrolling(delta: float):
	pass 

func _state_chasing(delta: float):
	pass
	
func _state_attacking(delta: float):
	pass

func _state_dying(delta: float):
	Logger.info(LOG_CAT, "'%s' (Player) está en estado DYING." % name, self)
	pass
