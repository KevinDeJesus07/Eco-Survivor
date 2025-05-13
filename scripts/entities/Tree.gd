extends BaseEntity

func _ready():
	super._ready() 
	
	Logger.priority(LOG_CAT, "'%s' (Tree specific) _ready completado." % name, self)

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
