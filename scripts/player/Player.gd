extends BaseEntity

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var placeholder: ColorRect = $VisualPlaceholder
@onready var hud2: Control = null
# var facing_dir: Vector2 = Vector2.DOWN
var gender: String = "female"
var score: int = 0

var default_max_hp := 10
var default_speed := 250
var default_score := 0

signal score_changed(new_score)

func _process(delta: float) -> void:
	if hud2 and get_viewport():
		var camera := get_viewport().get_camera_2d()
		if camera:
			var screen_pos = camera.unproject_position(global_position)
			hud2.global_position = screen_pos + Vector2(-100, -70)
			
func _ready():
	reset_to_defaults()
	super._ready()
	display_name = GameManager.player_name 
	GameManager.player_hp = hp
	GameManager.player_max_hp = max_hp
	GameManager.connect("player_name_changed", _on_player_name_changed)
	TimerLogic.tiempo_agotado.connect(_upgrade_level)
	can_patrol = false 
	Logger.info(LOG_CAT, "'%s' (Player) listo y controlado por input." % name, self)

func _upgrade_level():
	GameManager.player_max_hp_multiplier += GameManager.player_upgrade_increment_hp
	GameManager.player_speed_multiplier += GameManager.player_upgrade_increment_speed

	max_hp = int(round(default_max_hp * GameManager.player_max_hp_multiplier))
	speed = int(round(default_speed * GameManager.player_speed_multiplier))
	
	hp = max_hp
	
	GameManager.player_hp = hp
	GameManager.player_max_hp = max_hp
	
	if is_instance_valid(hud_instance) and hud_instance.has_method("update_health"):
		hud_instance.update_health(hp, max_hp)

		

func recycle(amount: int):
	score += amount
	GameManager.add_score(amount)

func _on_player_name_changed(new_name):
	display_name = new_name
	Logger.debug(LOG_CAT, "Nombre actualizado a: %s" % new_name, self)

func heal(amount: int):
	hp += amount
	if hp > max_hp:
		hp = max_hp
		
	GameManager.player_hp = hp
	GameManager.player_max_hp = max_hp
		
	if is_instance_valid(hud_instance) and hud_instance.has_method("update_health"):
		hud_instance.update_health(hp, max_hp)
		
	Logger.priority(LOG_CAT, "Player curado", self)

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
	var anim_to_play = GameManager.player_gender + "_idle_" + base_anim

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
	var anim_to_play = GameManager.player_gender + "_walk_" + base_anim

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
	
func reset_to_defaults():
	max_hp = default_max_hp
	hp = max_hp
	speed = default_speed
	score = default_score
	facing_dir = Vector2.DOWN
	GameManager.player_hp = hp
	GameManager.player_max_hp = max_hp
	GameManager.total_score = score
	
func _enter_dying_state():
	super._enter_dying_state()
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(3, false)
	set_collision_mask_value(4, false)
	var base_dir = _get_base_animation_name_from_direction()
	var anim_to_play = GameManager.player_gender + "_death_" + base_dir
	if not is_instance_valid(sprite) or not sprite.sprite_frames:
		queue_free()
		return
	
	var anim_exist = true
	if sprite.sprite_frames.has_animation(anim_to_play):
		sprite.play(anim_to_play)
	elif sprite.sprite_frames.has_animation("death_down"):
		sprite.play("death_down")
	else:
		anim_exist = false
		queue_free()
		return
		
	await sprite.animation_finished
	await get_tree().create_timer(3.0).timeout
		
	TimerLogic.detener_temporizador()
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")

	# Mostrar GameOver
