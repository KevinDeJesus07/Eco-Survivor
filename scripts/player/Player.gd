extends BaseEntity

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var placeholder: ColorRect = $VisualPlaceholder
@onready var hud2: Control = null
@onready var attack_effect: AnimatedSprite2D = $AttackEffect
@onready var attack_area: Area2D = $AttackArea

# var facing_dir: Vector2 = Vector2.DOWN
var gender: String = "female"
var score: int = 0

var default_max_hp := 10
var default_speed := 250
var default_score := 0

var attack_facing_dir: Vector2 = Vector2.DOWN
var attack_damage: int = 2

signal score_changed(new_score)

func _deal_damage():
	if not is_instance_valid(attack_area):
		return
	
	# Mueve la zona de ataque delante del jugador
	var offset := Vector2.ZERO
	var attack_rotation := 0.0
	if facing_dir.y > 0:
		offset = Vector2(-1.5, 10)
		attack_rotation = deg_to_rad(0)
	elif facing_dir.y < 0:
		offset = Vector2(-1.5, -30)
		attack_rotation = deg_to_rad(180)
	elif facing_dir.x > 0:
		offset = Vector2(80, 0)
		attack_rotation = deg_to_rad(90)
	elif facing_dir.x < 0:
		offset = Vector2(-100, 0)
		attack_rotation = deg_to_rad(-90)

	attack_area.position = offset
	attack_area.rotation = attack_rotation
	
	# Revisa qué enemigos están en el área
	for body in attack_area.get_overlapping_bodies():
		if body.has_method("take_damage") and not body.is_in_group("Dead"):
			body.take_damage(attack_damage)


func _play_attack_effect():
	if is_in_dying_state():
		return

	attack_effect.visible = true

	# Rotar 180° si se mira hacia arriba para cambiar visualmente el barrido
	if facing_dir.y < 0:
		attack_effect.rotation_degrees = 180
		attack_effect.position = Vector2(-5, -50)
	elif facing_dir.y > 0:
		attack_effect.rotation_degrees = 0
		attack_effect.position = Vector2(-5, 28)
	elif facing_dir.x > 0:
		attack_effect.rotation_degrees = -90
		attack_effect.position = Vector2(40, 0)
	elif facing_dir.x < 0:
		attack_effect.rotation_degrees = 90
		attack_effect.position = Vector2(-50, -15)

	# Asegurarnos que la animación 'attack' no está en bucle (esto se configura en el editor en el SpriteFrames)
	attack_effect.play("attack")

	_deal_damage()

	await attack_effect.animation_finished
	attack_effect.visible = false
	current_state = State.IDLE

func _update_aura_effect():
	if is_in_dying_state():
		attack_effect.visible = false
		attack_effect.stop()
		return

	attack_effect.visible = false
	attack_effect.stop()


func _process(delta: float) -> void:
	if hud2 and get_viewport():
		var camera := get_viewport().get_camera_2d()
		if camera:
			var screen_pos = camera.unproject_position(global_position)
			hud2.global_position = screen_pos + Vector2(-100, -70)
			
	match current_state:
		State.IDLE:
			_state_idle(delta)
			if Input.is_action_just_pressed("player_attack"):
				current_state = State.ATTACKING
		State.ATTACKING:
			_state_attacking(delta)
			
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
	
	#hp = max_hp
	
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
	
	_update_aura_effect()

	
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
		
	_update_aura_effect()


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
	# Permitir mover y cambiar facing_dir libremente durante el ataque
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * speed
		facing_dir = input_dir.normalized()
	else:
		velocity = Vector2.ZERO

	# Reproducir el efecto de ataque solo si no está ya reproduciéndose
	if not attack_effect.is_playing():
		_play_attack_effect()

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
	attack_effect.visible = false
	attack_effect.stop()

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


func take_damage(amount: int):
	if current_state == State.DYING:
		return

	hp -= amount
	GameManager.player_hp = hp
	Logger.debug(LOG_CAT, "'%s' recibió %d de daño. HP: %d/%d" % [name, amount, hp, max_hp], self)

	if is_instance_valid(hud_instance) and hud_instance.has_method("update_health"):
		hud_instance.update_health(hp, max_hp)

	if hp <= 0:
		hp = 0
		_change_state(State.DYING)
