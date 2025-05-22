extends BaseEntity

@export_group("Slime Behavior")
@export var leash_radius: float = 250.0
@export var attack_range: float = 100.0
@export var attack_damage: int = 1
@export var attack_cooldown_time: float = 1.5

# Nuevas propiedades para el ataque expandible
@export_group("Expandable Attack")
@export var attack_expansion_speed: float = 77.0
@export var attack_max_radius: float = 110.0       
@export var attack_start_radius: float = 20.0      

@onready var sprite: AnimatedSprite2D = $AnimatedSprite
@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var attack_cooldown_timer: Timer

var target_player: CharacterBody2D = null
var attack_current_radius: float = 0.0
var is_attack_expanding: bool = false
var attack_hit_applied: bool = false

func _ready():
	super._ready()
	
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

# --- PROCESO PRINCIPAL ---
func _process(delta: float):
	if is_attack_expanding:
		_update_expanding_attack(delta)

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

	# Inicializar el ataque expandible
	attack_current_radius = attack_start_radius
	is_attack_expanding = true
	attack_hit_applied = false

	var base_dir_name = _get_base_anim_name_from_facing_dir()
	var attack_anim_name = "attack_" + base_dir_name

	if sprite.sprite_frames.has_animation(attack_anim_name):
		sprite.play(attack_anim_name)
		if not sprite.is_connected("animation_finished", Callable(self, "_on_attack_animation_finished")):
			sprite.animation_finished.connect(Callable(self, "_on_attack_animation_finished"))
	else:
		Logger.warn(LOG_CAT, "Animación '%s' no encontrada." % attack_anim_name, self)
		# Si no hay animación, usar un timer simple
		if attack_cooldown_timer.is_connected("timeout", Callable(self, "_on_attack_animation_finished")):
			attack_cooldown_timer.timeout.disconnect(Callable(self, "_on_attack_animation_finished"))
		attack_cooldown_timer.timeout.connect(Callable(self, "_on_attack_animation_finished"))
		attack_cooldown_timer.wait_time = 0.8  # Duración del "ataque" sin animación
		attack_cooldown_timer.start()

func _enter_dying_state():
	super._enter_dying_state()
	# Detener cualquier ataque en progreso
	is_attack_expanding = false
	
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		if not sprite.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
			sprite.animation_finished.connect(Callable(self, "_on_death_animation_finished"))
	else:
		queue_free()

# --- LÓGICA DE ESTADOS ---

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

	# Si el jugador se aleja mucho, cancelar el ataque
	if not is_instance_valid(target_player) or \
	   global_position.distance_to(target_player.global_position) > attack_range * 1.5:
		_cancel_attack()
		return

func _state_dying(delta: float):
	if sprite.sprite_frames.has_animation("death") and sprite.is_playing() and sprite.animation == "death":
		return
	elif sprite.sprite_frames.has_animation("death") and not sprite.is_playing() and hp <= 0:
		queue_free()

# --- SISTEMA DE ATAQUE EXPANDIBLE ---

func _update_expanding_attack(delta: float):
	if not is_attack_expanding:
		return
	
	# Expandir el radio del ataque
	attack_current_radius += attack_expansion_speed * delta
	
	# Verificar si el jugador está dentro del radio actual y no hemos aplicado daño aún
	if not attack_hit_applied and is_instance_valid(target_player):
		var distance_to_player = global_position.distance_to(target_player.global_position)
		
		if distance_to_player <= attack_current_radius:
			_apply_attack_damage()
			attack_hit_applied = true
	
	# Si el radio alcanza el máximo, terminar la expansión
	if attack_current_radius >= attack_max_radius:
		attack_current_radius = attack_max_radius
		is_attack_expanding = false
		
		# Si llegamos al máximo sin haber golpeado, el ataque falló
		if not attack_hit_applied:
			Logger.info(LOG_CAT, "'%s' falló el ataque (jugador fuera de alcance)." % name, self)

# --- FINALIZACIÓN Y CANCELACIÓN DE ATAQUES ---

func _on_attack_animation_finished():
	# Limpiar conexiones
	if sprite.is_connected("animation_finished", Callable(self, "_on_attack_animation_finished")):
		sprite.animation_finished.disconnect(Callable(self, "_on_attack_animation_finished"))
	if attack_cooldown_timer.is_connected("timeout", Callable(self, "_on_attack_animation_finished")):
		attack_cooldown_timer.timeout.disconnect(Callable(self, "_on_attack_animation_finished"))
	
	# Finalizar el ataque
	is_attack_expanding = false
	
	# Iniciar cooldown y decidir siguiente estado
	attack_cooldown_timer.wait_time = attack_cooldown_time
	attack_cooldown_timer.start()
	_decide_next_state_after_cooldown_starts()

func _cancel_attack():
	# Detener expansión y limpiar conexiones
	is_attack_expanding = false
	
	if sprite.is_playing() and sprite.animation.begins_with("attack_"):
		sprite.stop()
	
	if sprite.is_connected("animation_finished", Callable(self, "_on_attack_animation_finished")):
		sprite.animation_finished.disconnect(Callable(self, "_on_attack_animation_finished"))
	if attack_cooldown_timer.is_connected("timeout", Callable(self, "_on_attack_animation_finished")):
		attack_cooldown_timer.timeout.disconnect(Callable(self, "_on_attack_animation_finished"))
		attack_cooldown_timer.stop()

	# Iniciar cooldown y cambiar estado
	attack_cooldown_timer.wait_time = attack_cooldown_time
	attack_cooldown_timer.start()
	_decide_next_state_after_cooldown_starts()

func _apply_attack_damage():
	if not is_instance_valid(target_player):
		return
		
	if target_player.has_method("take_damage"):
		target_player.take_damage(attack_damage)
		Logger.info(LOG_CAT, "'%s' hizo %d de daño a %s" % [name, attack_damage, target_player.name], self)
	else:
		Logger.warn(LOG_CAT, "'%s' no pudo hacer daño porque %s no tiene take_damage" % [name, target_player.name], self)

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

func _on_death_animation_finished():
	if sprite.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
		sprite.animation_finished.disconnect(Callable(self, "_on_death_animation_finished"))
	queue_free()

# --- FUNCIÓN PARA DEBUG VISUAL (OPCIONAL) ---
func _draw():
	if is_attack_expanding and Engine.is_editor_hint() == false:
		# Dibujar el círculo de ataque expandiéndose (solo en juego, para debug)
		draw_arc(Vector2.ZERO, attack_current_radius, 0, TAU, 32, Color.RED, 2.0)
		draw_arc(Vector2.ZERO, attack_max_radius, 0, TAU, 32, Color.WHITE, 1.0)
