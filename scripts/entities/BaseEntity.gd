# BaseEntity.gd
extends CharacterBody2D
class_name BaseEntity

const LOG_CAT: String = "BASE_ENTITY"

@export_group("Base Stats")
#@export var display_name: String = "default"
@export var max_hp: int = 100
@export var speed: float = 75.0

@export_group("Patrolling Behavior")
@export var can_patrol: bool = true
@export var patrol_idle_time: float = 2.0
@export var patrol_stuck_time: float = 4.0

@export var patrol_area_mode: String = "RADIUS"

@export_group("Patrolling Area - Radius Mode")
@export var patrol_center_offset: Vector2 = Vector2.ZERO
@export var patrol_radius: float = 100.0

@export_group("Patrolling Area - Rectangle Mode")
@export var patrol_rect_min_offset: Vector2 = Vector2(-100, -50)
@export var patrol_rect_max_offset: Vector2 = Vector2(100, 50)

@export var hud: PackedScene
var hud_instance: Control = null

var hp: int
var initial_pos: Vector2
var patrol_area_center: Vector2
var curr_patrol_target: Vector2

enum State { IDLE, PATROLLING, CHASING, ATTACKING, DYING, RETURNING }
var current_state: State = State.IDLE
var prev_state: State
var facing_dir: Vector2 = Vector2.DOWN
var idle_timer: Timer
var stuck_timer: Timer

signal display_name_changed(new_name)

var display_name: String = "SLime":
	set(value):
		if display_name != value:
			display_name = value
			emit_signal("display_name_changed", value)

func _ready():
	hp = max_hp
	initial_pos = global_position
	patrol_area_center = initial_pos + patrol_center_offset

	idle_timer = Timer.new()
	idle_timer.name = "IdleTimer"
	add_child(idle_timer)
	idle_timer.wait_time = patrol_idle_time
	idle_timer.one_shot = true
	idle_timer.timeout.connect(_on_idle_timer_timeout)

	stuck_timer = Timer.new()
	stuck_timer.name = "StuckTimer"
	add_child(stuck_timer)
	stuck_timer.wait_time = patrol_stuck_time
	stuck_timer.one_shot = true
	stuck_timer.timeout.connect(_on_stuck_timer_timeout)

	Logger.debug(LOG_CAT, "'%s' ready. HP: %d/%d. Can Patrol: %s" % [name, hp, max_hp, can_patrol], self)

	if is_instance_valid(hud):
		hud_instance = hud.instantiate()
		add_child(hud_instance)
		hud_instance.position.y = -100
		hud_instance.position.x = -70
		if hud_instance.has_method("initialize_hud"):
			hud_instance.initialize_hud(self)
	else:
		Logger.warn(LOG_CAT, "hud no asignado para " + str(name), self)

	_execute_enter_state_logic(current_state)

func _physics_process(delta: float):
	match current_state:
		State.IDLE: _state_idle(delta)
		State.PATROLLING: _state_patrolling(delta)
		State.CHASING: _state_chasing(delta)
		State.ATTACKING: _state_attacking(delta)
		State.DYING: _state_dying(delta)
		State.RETURNING: _state_returning(delta)
	move_and_slide()

func _change_state(new_state: State):
	if new_state == current_state:
		return

	Logger.debug(LOG_CAT, "'%s' cambiando estado de '%s' a '%s'" % [name, State.keys()[current_state], State.keys()[new_state]], self)
	prev_state = current_state
	current_state = new_state
	_execute_enter_state_logic(new_state)

func _execute_enter_state_logic(state_to_enter: State):
	Logger.debug(LOG_CAT, "'%s' ejecutando lógica de entrada para estado: %s" % [name, State.keys()[state_to_enter]], self)
	match state_to_enter:
		State.IDLE: _enter_idle_state()
		State.PATROLLING: _enter_patrolling_state()
		State.CHASING: _enter_chasing_state()
		State.ATTACKING: _enter_attacking_state()
		State.DYING: _enter_dying_state()
		State.RETURNING: _enter_returning_state()

func _enter_idle_state():
	Logger.debug(LOG_CAT, "'%s' (Base) entrando a IDLE." % name, self)
	velocity = Vector2.ZERO
	stuck_timer.stop()
	if can_patrol and is_instance_valid(idle_timer):
		idle_timer.start()

func _enter_patrolling_state():
	Logger.debug(LOG_CAT, "'%s' (Base) entrando a PATROLLING." % name, self)
	stuck_timer.stop()
	_set_new_patrol_target()
	if curr_patrol_target != global_position and is_instance_valid(stuck_timer):
		stuck_timer.start()
	elif is_instance_valid(stuck_timer):
		Logger.debug(LOG_CAT, "'%s' no necesita moverse para patrullar, volviendo a IDLE." % name, self)
		_change_state(State.IDLE)

func _enter_chasing_state():
	Logger.debug(LOG_CAT, "'%s' (Base) entrando a CHASING." % name, self)
	idle_timer.stop()
	stuck_timer.stop()

func _enter_attacking_state():
	Logger.debug(LOG_CAT, "'%s' (Base) entrando a ATTACKING." % name, self)
	velocity = Vector2.ZERO
	idle_timer.stop()
	stuck_timer.stop()

func _enter_dying_state():
	Logger.debug(LOG_CAT, "'%s' (Base) entrando a DYING." % name, self)
	velocity = Vector2.ZERO
	idle_timer.stop()
	stuck_timer.stop()
	if is_instance_valid(hud_instance):
		hud_instance.visible = false

func _enter_returning_state():
	Logger.debug(LOG_CAT, "'%s' (Base) entrando a RETURNING." % name, self)
	idle_timer.stop()
	stuck_timer.stop()

func _state_idle(delta: float):
	pass

func _state_patrolling(delta: float):
	if curr_patrol_target == global_position:
		_change_state(State.IDLE)
		return

	var direction_to_target = global_position.direction_to(curr_patrol_target)

	if global_position.distance_to(curr_patrol_target) > 5.0:
		velocity = direction_to_target * speed
	else:
		Logger.debug(LOG_CAT, "'%s' llegó a destino de patrulla. Entrando a IDLE." % name, self)
		_change_state(State.IDLE)

func _state_chasing(delta: float):
	pass

func _state_attacking(delta: float):
	pass

func _state_dying(delta: float):
	pass

func _state_returning(delta: float):
	pass

func _set_new_patrol_target():
	if not can_patrol:
		curr_patrol_target = global_position
		return

	if patrol_area_mode == "RADIUS":
		var random_angle = randf_range(0, TAU)
		var random_radius = randf_range(0, patrol_radius)
		curr_patrol_target = patrol_area_center + Vector2(cos(random_angle), sin(random_angle)) * random_radius
	elif patrol_area_mode == "RECTANGLE":
		var random_x = randf_range(patrol_rect_min_offset.x, patrol_rect_max_offset.x)
		var random_y = randf_range(patrol_rect_min_offset.y, patrol_rect_max_offset.y)
		curr_patrol_target = patrol_area_center + Vector2(random_x, random_y)
	else:
		Logger.warn(LOG_CAT, "'%s' modo de patrulla desconocido: '%s'. No se establece nuevo objetivo." % [name, patrol_area_mode], self)
		curr_patrol_target = global_position
		return

	Logger.debug(LOG_CAT, "'%s' nuevo destino de patrulla (modo %s): %s" % [name, patrol_area_mode, curr_patrol_target], self)

func _on_idle_timer_timeout():
	if current_state == State.IDLE and can_patrol:
		Logger.debug(LOG_CAT, "'%s' terminó tiempo en IDLE. Volviendo a PATROLLING." % name, self)
		_change_state(State.PATROLLING)

func _on_stuck_timer_timeout():
	if current_state == State.PATROLLING:
		Logger.warn(LOG_CAT, "'%s' ¡Timer de Atascado! No pudo alcanzar %s. Volviendo a IDLE." % [name, curr_patrol_target], self)
		_change_state(State.IDLE)

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
