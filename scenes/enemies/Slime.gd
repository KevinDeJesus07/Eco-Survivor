extends BaseEntity

@export_group("Slime Behavior")
@export var leash_radius: float = 250.0
@export var attack_range: float = 100.0
@export var actual_attack_hit_range: float = 110.0
@export var attack_damage: int = 1
@export var attack_cooldown_time: float = 1.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite
@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var attack_cooldown_timer: Timer

var target_player: CharacterBody2D = null

func _ready():
	super._ready()
	
	# Crear timer de cooldown si no existe para evitar duplicados
	if not has_node("AttackCooldownTimer"):
		attack_cooldown_timer = Timer.new()
		attack_cooldown_timer.name = "AttackCooldownTimer"
		add_child(attack_cooldown_timer)
	else:
		attack_cooldown_timer = get_node("AttackCooldownTimer")

	attack_cooldown_timer.wait_time = attack_cooldown_time
	attack_cooldown_timer.one_shot = true

	if is_instance_valid(player_detection_area):
		player_detection_area.body_entered.connect(_on_player_detection_area_body_entered)
		player_detection_area.body_exited.connect(_on_player_detection_area_body_exited)
	else:
		Logger.error(LOG_CAT, "Nodo PlayerDetectionArea no encontrado en SlimeEnemy!", self)

	Logger.info(LOG_CAT, "'%s' (Slime) listo." % name, self)

# --- ESTADOS ---

func _enter_idle_state():
	super._enter_idle_state()
	_update_animation()

func _enter_patrolling_state():
	super._enter_patrolling_state()
	_update_animation()

func _enter_chasing_state():
	super._enter_chasing_state()
	Logger.info(LOG_CAT, "'%s' (Slime) entrando a CHASING." % name, self)
	_update_animation()

func _enter_attacking_state():
	super._enter_attacking_state()
	Logger.info(LOG_CAT, "'%s' (Slime) entrando a ATACANDO." % name, self)

	var base_dir_name = _get_base_anim_name_from_facing_dir()
	var attack_anim_name = "attack_" + base_dir_name

	if sprite.sprite_frames.has_animation(attack_anim_name):
		sprite.play(attack_anim_name)
		if not sprite.is_connected("animation_finished", Callable(self, "_apply_attack_damage")):
			sprite.animation_finished.connect(Callable(self, "_apply_attack_damage"))
	else:
		Logger.warn(LOG_CAT, "Animación '%s' no encontrada. Usando pseudo-timer." % attack_anim_name, self)
		# Desconectar posibles conexiones antiguas para evitar conflictos
		if attack_cooldown_timer.is_connected("timeout", Callable(self, "_apply_attack_damage")):
			attack_cooldown_timer.timeout.disconnect(Callable(self, "_apply_attack_damage"))
		attack_cooldown_timer.timeout.connect(Callable(self, "_apply_attack_damage"))
		attack_cooldown_timer.wait_time = 0.5
		attack_cooldown_timer.start()

func _enter_dying_state():
	super._enter_dying_state()
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		if not sprite.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
			sprite.animation_finished.connect(Callable(self, "_on_death_animation_finished"))
	else:
		queue_free()

func _state_idle(delta: float):
	_update_animation()

func _state_patrolling(delta: float):
	super._state_patrolling(delta)
	_update_animation()

func _state_chasing(delta: float):
	if not is_instance_valid(target_player):
		_change_state(State.PATROLLING)
		return

	if global_position.distance_to(initial_pos) > leash_radius:
		target_player = null
		_change_state(State.PATROLLING)
		return

	var direction = global_position.direction_to(target_player.global_position)
	velocity = direction * speed

	if velocity.length_squared() > 0.01:
		facing_dir = velocity.normalized()
	_update_animation()

	var dist_to_player = global_position.distance_to(target_player.global_position)
	if dist_to_player <= attack_range and attack_cooldown_timer.is_stopped():
		_change_state(State.ATTACKING)

func _state_attacking(delta: float):
	super._state_attacking(delta)

	if not is_instance_valid(target_player) or \
	   global_position.distance_to(target_player.global_position) > actual_attack_hit_range * 1.2:

		if sprite.is_playing() and sprite.animation.begins_with("attack_"):
			sprite.stop()
		if sprite.is_connected("animation_finished", Callable(self, "_apply_attack_damage")):
			sprite.animation_finished.disconnect(Callable(self, "_apply_attack_damage"))
		if attack_cooldown_timer.is_connected("timeout", Callable(self, "_apply_attack_damage")):
			attack_cooldown_timer.timeout.disconnect(Callable(self, "_apply_attack_damage"))
			attack_cooldown_timer.stop()

		attack_cooldown_timer.wait_time = attack_cooldown_time
		attack_cooldown_timer.start()
		_decide_next_state_after_cooldown_starts()
		return

func _state_dying(delta: float):
	if sprite.sprite_frames.has_animation("death") and sprite.is_playing() and sprite.animation == "death":
		return
	elif sprite.sprite_frames.has_animation("death") and not sprite.is_playing() and hp <= 0:
		queue_free()

# --- FIN DE ATAQUE Y APLICAR DAÑO ---

func _apply_attack_damage():
	Logger.info(LOG_CAT, "LLAMADA A: _apply_attack_damage", self)

	if sprite.is_connected("animation_finished", Callable(self, "_apply_attack_damage")):
		sprite.animation_finished.disconnect(Callable(self, "_apply_attack_damage"))
	if attack_cooldown_timer.is_connected("timeout", Callable(self, "_apply_attack_damage")):
		attack_cooldown_timer.timeout.disconnect(Callable(self, "_apply_attack_damage"))

	if is_instance_valid(target_player) and global_position.distance_to(target_player.global_position) <= actual_attack_hit_range:
		if target_player.has_method("take_damage"):
			target_player.take_damage(attack_damage)
			Logger.info(LOG_CAT, "'%s' hizo %d de daño a %s" % [name, attack_damage, target_player.name], self)
		else:
			Logger.warn(LOG_CAT, "'%s' no pudo hacer daño porque %s no tiene take_damage" % [name, target_player.name], self)
	else:
		Logger.info(LOG_CAT, "'%s' falló el ataque (jugador fuera de alcance)." % name, self)

	attack_cooldown_timer.wait_time = attack_cooldown_time
	attack_cooldown_timer.start()
	_decide_next_state_after_cooldown_starts()

func _decide_next_state_after_cooldown_starts():
	if not is_instance_valid(target_player):
		_change_state(State.PATROLLING)
		return

	var dist = global_position.distance_to(target_player.global_position)

	if dist <= attack_range:
		_change_state(State.CHASING)
	elif player_detection_area.overlaps_body(target_player):
		_change_state(State.CHASING)
	else:
		target_player = null
		_change_state(State.PATROLLING)

# --- DETECCIÓN DE JUGADOR ---

func _on_player_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		target_player = body as CharacterBody2D
		if current_state not in [State.ATTACKING, State.DYING]:
			_change_state(State.CHASING)

func _on_player_detection_area_body_exited(body):
	if body == target_player:
		if current_state == State.CHASING:
			target_player = null
			_change_state(State.PATROLLING)

# --- ANIMACIONES ---

func _update_animation():
	if not is_instance_valid(sprite) or not sprite.sprite_frames:
		return

	var anim_prefix = "idle_"
	if current_state in [State.PATROLLING, State.CHASING] and velocity.length_squared() > 0.1:
		anim_prefix = "walk_"

	var base_dir = _get_base_anim_name_from_facing_dir()
	var anim_to_play = anim_prefix + base_dir

	if sprite.sprite_frames.has_animation(anim_to_play):
		if sprite.animation != anim_to_play or not sprite.is_playing():
			sprite.play(anim_to_play)
	elif sprite.sprite_frames.has_animation("idle_" + base_dir):
		sprite.play("idle_" + base_dir)
	elif sprite.sprite_frames.has_animation(anim_prefix + "down"):
		sprite.play(anim_prefix + "down")

func _get_base_anim_name_from_facing_dir() -> String:
	if facing_dir == Vector2.ZERO:
		return "down"
	if abs(facing_dir.y) > abs(facing_dir.x):
		return "up" if facing_dir.y < 0 else "down"
	else:
		return "left" if facing_dir.x < 0 else "right"

# --- Animación de muerte terminada ---

func _on_death_animation_finished():
	if sprite.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
		sprite.animation_finished.disconnect(Callable(self, "_on_death_animation_finished"))
	queue_free()
