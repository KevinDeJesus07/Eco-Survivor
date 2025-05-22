extends BaseEntity

@onready var sprite: AnimatedSprite2D = $AnimatedSprite

func _ready():
	super._ready() 
	can_patrol = false
	if is_instance_valid(sprite):
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
			sprite.play("default")
			Logger.debug(LOG_CAT, "'%s' (Tree) iniciando animación 'default'.", self)
		else:
			Logger.warn(LOG_CAT, "'%s' (Tree) no se encontró la animación 'default' o SpriteFrames." % name, self)
	else:
		Logger.error(LOG_CAT, "'%s' (Tree) no se encontró el nodo AnimatedSprite2D." % name, self)
	Logger.debug(LOG_CAT, "'%s' (Tree specific) _ready completado." % name, self)

func _state_patrolling(delta):
	pass
	
func _state_idle(delta):
	pass
	
func _state_dying(delta):
	pass
	
func _state_chasing(delta):
	pass
	
func _state_attacking(delta):
	pass
