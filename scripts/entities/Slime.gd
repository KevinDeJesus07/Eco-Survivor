extends BaseEntity

var base_speed = 200
var base_attack_damage = 2

@export_group("Slime Behavior")
@export var leash_radius: float = 250.0
@export var attack_range: float = 100.0
@export var attack_damage: int = 1
@export var attack_cooldown_time: float = 1.5
@export var max_patience: float = 5.0 # Tiempo (seg) que puede estar fuera del leash persiguiendo
@export var patience_recovery_rate: float = 0.5 # Cuánto recupera por segundo dentro del leash

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
var current_patience: float = 0.0 # Paciencia actual

const LEASH_MARGIN := 32 # Margen para evitar rebotes en el leash

func _ready():
	super._ready()
	add_to_group("enemigos")

	current_patience = max_patience # Empezar con paciencia al máximo

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
	
	update_stats()

func update_stats():
	speed = int(round(base_speed * GameManager.enemy_speed_multiplier))
	attack_damage = int(round(base_attack_damage * GameManager.enemy_damage_multiplier))


# --- PROCESO PRINCIPAL ---
func _process(delta: float):
	if is_attack_expanding:
		_update_expanding_attack(delta)
	
	# Actualizar la dirección de la cara (opcional pero útil para animaciones)
	if velocity.length_squared() > 0.1:
		facing_dir = velocity.normalized()


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
	velocity = Vector2.ZERO # Asegurarnos de que se detiene al atacar

	# Inicializar el ataque expandible
	attack_current_radius = attack_start_radius
	is_attack_expanding = true
	attack_hit_applied = false

	var base_dir_name = _get_base_anim_name_from_facing_dir()
	var attack_anim_name = "attack_" + base_dir_name

	if sprite.sprite_frames.has_animation(attack_anim_name):
		sprite.play(attack_anim_name)
		# Conectar solo si no está conectada ya
		if not sprite.is_connected("animation_finished", Callable(self, "_on_attack_animation_finished")):
			sprite.animation_finished.connect(Callable(self, "_on_attack_animation_finished"))
	else:
		Logger.warn(LOG_CAT, "Animación '%s' no encontrada." % attack_anim_name, self)
		# Si no hay animación, usar un timer simple (desconectar primero por si acaso)
		if attack_cooldown_timer.is_connected("timeout", Callable(self, "_on_attack_animation_finished")):
			attack_cooldown_timer.timeout.disconnect(Callable(self, "_on_attack_animation_finished"))
		attack_cooldown_timer.timeout.connect(Callable(self, "_on_attack_animation_finished"))
		attack_cooldown_timer.wait_time = 0.8 # Duración del "ataque" sin animación
		attack_cooldown_timer.start()

func _enter_dying_state():
	super._enter_dying_state()
	is_attack_expanding = false # Detener cualquier ataque en progreso
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		if not sprite.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
			sprite.animation_finished.connect(Callable(self, "_on_death_animation_finished"))
	else:
		queue_free() # Si no hay animación de muerte, desaparecer

func _enter_returning_state():
	super._enter_returning_state()
	Logger.info(LOG_CAT, "'%s' (Slime) se quedó sin paciencia. Volviendo a casa." % name, self)
	#target_player = null # Dejar de fijarse en el jugador


# --- LÓGICA DE ESTADOS ---

func _state_idle(delta: float):
	super._state_idle(delta)
	_update_animation()
	# Si estamos en IDLE, recuperamos paciencia
	current_patience = min(current_patience + patience_recovery_rate * delta, max_patience)
	# Si vemos al jugador mientras estamos en IDLE, lo perseguimos
	if is_instance_valid(target_player) and player_detection_area.overlaps_body(target_player):
		_change_state(State.CHASING)

func _state_patrolling(delta: float):
	super._state_patrolling(delta)
	_update_animation()
	# Si estamos patrullando, recuperamos paciencia
	current_patience = min(current_patience + patience_recovery_rate * delta, max_patience)
	# Si vemos al jugador mientras patrullamos, lo perseguimos
	if is_instance_valid(target_player) and player_detection_area.overlaps_body(target_player):
		_change_state(State.CHASING)

func _state_chasing(delta: float):
	# 1. Comprobaciones de Validez: ¿Sigue existiendo el jugador? ¿Sigue en el área?
	if not is_instance_valid(target_player) or not player_detection_area.overlaps_body(target_player):
		target_player = null
		_change_state(State.PATROLLING)
		return

	var distance_to_player = global_position.distance_to(target_player.global_position)
	var distance_to_center = global_position.distance_to(initial_pos)

	# 2. Comprobar si podemos ATACAR
	if distance_to_player <= attack_range and attack_cooldown_timer.is_stopped():
		_change_state(State.ATTACKING)
		return

	# 3. Lógica de Leash y Paciencia
	if distance_to_center > leash_radius:
		# Estamos fuera del leash, ¡gastamos paciencia!
		current_patience -= delta
		Logger.debug(LOG_CAT, "'%s' Fuera de leash. Paciencia: %.1f" % [name, current_patience], self)
		if current_patience <= 0:
			_change_state(State.RETURNING)
			return
		# Si aún tenemos paciencia, seguimos persiguiendo
		var direction = (target_player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		# Estamos dentro del leash, recuperamos paciencia y perseguimos
		current_patience = min(current_patience + patience_recovery_rate * delta, max_patience)
		var direction = (target_player.global_position - global_position).normalized()
		velocity = direction * speed
		# Si estamos muy cerca pero esperando cooldown, nos detenemos para no empujar
		if distance_to_player <= attack_range:
			velocity = Vector2.ZERO

	_update_animation()

func _state_attacking(delta: float):
	super._state_attacking(delta) # Mantiene velocidad a CERO
	# Si el jugador se aleja mucho, cancelar el ataque
	if not is_instance_valid(target_player) or \
	   global_position.distance_to(target_player.global_position) > attack_range * 1.5:
		_cancel_attack()
		return

func _state_returning(delta: float):
	var distance_to_center = global_position.distance_to(initial_pos)

	# Si llegamos al centro (o casi)
	if distance_to_center <= 5.0:
		velocity = Vector2.ZERO
		_change_state(State.PATROLLING)
		return
	else:
		# Moverse hacia el centro
		var direction_to_center = (initial_pos - global_position).normalized()
		velocity = direction_to_center * speed

	_update_animation() # Usar animación de caminar
	# ¡Importante! Si el jugador entra de nuevo en el área mientras volvemos,
	# la función _on_player_detection_area_body_entered se encargará de
	# cambiar el estado de nuevo a CHASING.

func _state_dying(delta: float):
	# La lógica de animación y queue_free() ya se maneja en _enter_dying_state
	# y _on_death_animation_finished, así que aquí no hacemos nada.
	pass

# --- SISTEMA DE ATAQUE EXPANDIBLE ---

func _update_expanding_attack(delta: float):
	if not is_attack_expanding:
		return

	attack_current_radius += attack_expansion_speed * delta

	if not attack_hit_applied and is_instance_valid(target_player):
		var distance_to_player = global_position.distance_to(target_player.global_position)
		if distance_to_player <= attack_current_radius:
			_apply_attack_damage()
			attack_hit_applied = true

	if attack_current_radius >= attack_max_radius:
		attack_current_radius = attack_max_radius
		is_attack_expanding = false
		if not attack_hit_applied:
			Logger.info(LOG_CAT, "'%s' falló el ataque (jugador fuera de alcance)." % name, self)

# --- FINALIZACIÓN Y CANCELACIÓN DE ATAQUES ---

func _on_attack_animation_finished():
	if sprite.is_connected("animation_finished", Callable(self, "_on_attack_animation_finished")):
		sprite.animation_finished.disconnect(Callable(self, "_on_attack_animation_finished"))
	if attack_cooldown_timer.is_connected("timeout", Callable(self, "_on_attack_animation_finished")):
		attack_cooldown_timer.timeout.disconnect(Callable(self, "_on_attack_animation_finished"))

	is_attack_expanding = false
	attack_cooldown_timer.wait_time = attack_cooldown_time
	attack_cooldown_timer.start()
	_decide_next_state_after_cooldown_starts()

func _cancel_attack():
	is_attack_expanding = false
	if sprite.is_playing() and sprite.animation.begins_with("attack_"):
		sprite.stop()
	if sprite.is_connected("animation_finished", Callable(self, "_on_attack_animation_finished")):
		sprite.animation_finished.disconnect(Callable(self, "_on_attack_animation_finished"))
	if attack_cooldown_timer.is_connected("timeout", Callable(self, "_on_attack_animation_finished")):
		attack_cooldown_timer.timeout.disconnect(Callable(self, "_on_attack_animation_finished"))
		attack_cooldown_timer.stop()

	attack_cooldown_timer.wait_time = attack_cooldown_time
	attack_cooldown_timer.start()
	_decide_next_state_after_cooldown_starts()

func _apply_attack_damage():
	if not is_instance_valid(target_player): return
	if target_player.has_method("take_damage"):
		target_player.take_damage(attack_damage)
		Logger.info(LOG_CAT, "'%s' hizo %d de daño a %s" % [name, attack_damage, target_player.name], self)
	else:
		Logger.warn(LOG_CAT, "'%s' no pudo hacer daño porque %s no tiene take_damage" % [name, target_player.name], self)

func _decide_next_state_after_cooldown_starts():
	# Tras atacar (o cancelar), decidimos si seguir persiguiendo o volver a patrullar.
	# Dejamos que CHASING decida si puede atacar de nuevo.
	if is_instance_valid(target_player) and player_detection_area.overlaps_body(target_player):
		_change_state(State.CHASING)
	else:
		target_player = null
		_change_state(State.PATROLLING)

# --- DETECCIÓN DE JUGADOR ---

func _on_player_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		target_player = body as CharacterBody2D
		# Si estamos en cualquier estado "no hostil" o volviendo, empezamos a perseguir.
		if current_state in [State.IDLE, State.PATROLLING, State.RETURNING]:
			_change_state(State.CHASING)

func _on_player_detection_area_body_exited(body):
	if body == target_player:
		# Si el jugador sale Y estamos persiguiendo (no volviendo o atacando),
		# dejamos de perseguir y volvemos a patrullar.
		if current_state == State.CHASING:
			target_player = null
			_change_state(State.PATROLLING)

# --- ANIMACIONES ---

func _update_animation():
	if not is_instance_valid(sprite) or not sprite.sprite_frames: return

	var anim_prefix = "idle_"
	# Usar animación de caminar si nos movemos en Patrolling, Chasing o Returning
	if current_state in [State.PATROLLING, State.CHASING, State.RETURNING] and velocity.length_squared() > 0.1:
		anim_prefix = "walk_"

	var base_dir = _get_base_anim_name_from_facing_dir()
	var anim_to_play = anim_prefix + base_dir

	# Lógica para reproducir animación (mejorada para evitar reinicios innecesarios)
	if sprite.sprite_frames.has_animation(anim_to_play):
		if sprite.animation != anim_to_play or not sprite.is_playing():
			sprite.play(anim_to_play)
	elif sprite.sprite_frames.has_animation("idle_" + base_dir): # Fallback a idle_dir
		if sprite.animation != ("idle_" + base_dir) or not sprite.is_playing():
			sprite.play("idle_" + base_dir)
	elif sprite.sprite_frames.has_animation("idle_down"): # Fallback a idle_down
		if sprite.animation != "idle_down" or not sprite.is_playing():
			sprite.play("idle_down")

func _get_base_anim_name_from_facing_dir() -> String:
	# Usa la dirección de la cara, pero si es CERO (atacando/idle), usa la anterior.
	var dir_to_check = facing_dir
	if dir_to_check == Vector2.ZERO: # Si está quieto, usa la última dirección que tuvo
		if velocity.length_squared() > 0.1: # A menos que se esté moviendo ahora mismo
			dir_to_check = velocity.normalized()
		else: # Si no, mantén la última dirección de cara válida
			if prev_state in [State.PATROLLING, State.CHASING]:
				# Intenta adivinarla por la velocidad anterior (si la hubiera)
				# O simplemente mantén la última conocida. Para simplificar, usamos la última.
				pass # Mantiene la facing_dir actual (que no es ZERO si se movió antes)

	# Si sigue siendo CERO, por defecto 'down'
	if dir_to_check == Vector2.ZERO: return "down"

	if abs(dir_to_check.y) > abs(dir_to_check.x):
		return "up" if dir_to_check.y < 0 else "down"
	else:
		return "left" if dir_to_check.x < 0 else "right"

func _on_death_animation_finished():
	if sprite.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
		sprite.animation_finished.disconnect(Callable(self, "_on_death_animation_finished"))
	queue_free()

# --- FUNCIÓN PARA DEBUG VISUAL (OPCIONAL) ---
func _draw():
	if is_attack_expanding: # No necesitamos Engine.is_editor_hint() aquí
		draw_arc(Vector2.ZERO, attack_current_radius, 0, TAU, 32, Color.RED, 2.0)
		draw_arc(Vector2.ZERO, attack_max_radius, 0, TAU, 32, Color.WHITE, 1.0)
	
	# Opcional: Dibujar el leash y el radio de ataque para debug
	#draw_arc(to_local(initial_pos), leash_radius, 0, TAU, 32, Color.BLUE, 1.0, true)
	#draw_arc(Vector2.ZERO, attack_range, 0, TAU, 32, Color.ORANGE, 1.0, true)
