extends BaseEntity

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var placeholder: ColorRect = $VisualPlaceholder
@onready var hud2: Control = null
# var facing_dir: Vector2 = Vector2.DOWN

func _process(delta: float) -> void:
	if hud2 and get_viewport():
		var camera := get_viewport().get_camera_2d()
		if camera:
			var screen_pos = camera.unproject_position(global_position)
			hud2.global_position = screen_pos + Vector2(-100, -70)
func _ready():
	super._ready() 
	can_patrol = false 
	Logger.info(LOG_CAT, "'%s' (Player) listo y controlado por input." % name, self)

func _enter_idle_state():
	super._enter_idle_state()
	_update_idle_animation()

func _state_idle(delta: float):
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * speed 
		facing_dir = input_dir.normalized()
		_update_walk_animation()
	else:
		velocity = Vector2.ZERO
		_update_idle_animation()
	
func _get_base_animation_name_from_direction() -> String:
	var base_anim_name: String = "down"
	var threshold_cardinal = 0.8
	var threshold_diagonal_y_influence = 0.3

	if facing_dir == Vector2.ZERO:
		return "down"

	if facing_dir.y > threshold_cardinal:
		base_anim_name = "down"
	elif facing_dir.y < -threshold_cardinal:
		base_anim_name = "up"
	elif facing_dir.x < 0:
		if facing_dir.y > threshold_diagonal_y_influence:
			base_anim_name = "down_left"
		elif facing_dir.y < -threshold_diagonal_y_influence:
			base_anim_name = "up_left"
		else:
			base_anim_name = "down_left"
	elif facing_dir.x > 0:
		if facing_dir.y > threshold_diagonal_y_influence:
			base_anim_name = "down_right"
		elif facing_dir.y < -threshold_diagonal_y_influence:
			base_anim_name = "up_right"
		else:
			base_anim_name = "down_right"

	return base_anim_name

func _update_idle_animation():
	if not is_instance_valid(sprite) or not sprite.sprite_frames:
		Logger.error(LOG_CAT, "Sprite o SpriteFrames no válidos en _update_idle_animation.", self)
		return

	var base_anim = _get_base_animation_name_from_direction()
	var anim_to_play = "idle_" + base_anim

	if facing_dir == Vector2.ZERO and sprite.animation.begins_with("idle_") and sprite.is_playing():
		return
	if facing_dir == Vector2.ZERO and not (sprite.animation.begins_with("idle_") and sprite.is_playing()):
		anim_to_play = "idle_down"

	if sprite.sprite_frames.has_animation(anim_to_play):
		if sprite.animation != anim_to_play or not sprite.is_playing():
			sprite.play(anim_to_play)
			Logger.debug(LOG_CAT, "Player Anim IDLE: " + anim_to_play + " (facing_dir: " + str(facing_dir.round()) + ")", self)
	else: 
		Logger.warn(LOG_CAT, "Animación IDLE '" + anim_to_play + "' no encontrada. Usando 'idle_down'.", self)
		if sprite.sprite_frames.has_animation("idle_down") and (sprite.animation != "idle_down" or not sprite.is_playing()):
			sprite.play("idle_down")

func _update_walk_animation():
	if not is_instance_valid(sprite) or not sprite.sprite_frames:
		Logger.error(LOG_CAT, "Sprite o SpriteFrames no válidos en _update_walk_animation.", self)
		return

	var base_anim = _get_base_animation_name_from_direction()
	var anim_to_play = "walk_" + base_anim

	if facing_dir == Vector2.ZERO:
		_update_idle_animation()
		return

	if sprite.sprite_frames.has_animation(anim_to_play):
		if sprite.animation != anim_to_play or not sprite.is_playing():
			sprite.play(anim_to_play)
			Logger.debug(LOG_CAT, "Player Anim WALK: " + anim_to_play + " (facing_dir: " + str(facing_dir.round()) + ")", self)
	else: 
		Logger.warn(LOG_CAT, "Animación WALK '" + anim_to_play + "' no encontrada. Usando 'walk_down'.", self)
		if sprite.sprite_frames.has_animation("walk_down") and (sprite.animation != "walk_down" or not sprite.is_playing()):
			sprite.play("walk_down")

func _state_patrolling(delta: float):
	pass 

func _state_chasing(delta: float):
	pass
	
func _state_attacking(delta: float):
	pass

func _state_dying(delta: float):
	Logger.info(LOG_CAT, "'%s' (Player) está en estado DYING." % name, self)
	pass
