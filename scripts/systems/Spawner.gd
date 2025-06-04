@tool
extends Node2D

enum SpawnMode {
	TIMER,
	ON_EVENT,
	AT_START,
	MAINTAIN
}

@export_group("Main Config")
@export var scene_to_spawn: PackedScene
@export var spawn_mode: SpawnMode = SpawnMode.TIMER
@export var group_for_spawned_entities: String = ""
@export var spawner_type: String = "slime"  # "slime", "heal", "trash"

@export_group("Limits and Counts")
@export var spawn_count: int = 5
@export var max_instances_per_spawner: int = 10

@export_group("Timer")
@export var time_interval: float = 5.0
@export var initial_delay: float = 0.0

@export_group("Collision Check")
@export var check_collision: bool = true
@export var collision_mask: int = 1
@export var max_spawn_attempts: int = 10

@export_group("Nodos requeridos")
@export var spawn_area_node_path: NodePath = ^"SpawnArea"
@export var spawn_timer_node_path: NodePath = ^"SpawnTimer"

var _spawn_area: Area2D
var _spawn_shape_owner_id: int
var _spawn_collision_shape: CollisionShape2D
var _spawn_timer: Timer
var _active_instances: Array[Node] = []
var _can_spawn: bool = true

var default_time_interval := 5.0
var default_max_instances := 5
var default_spawn_count := 1

const LOG_CAT: String = "SPAWNER"

func _ready():
	add_to_group("spawners")

	reset_to_defaults() 

	_spawn_area = get_node_or_null(spawn_area_node_path)
	_spawn_timer = get_node_or_null(spawn_timer_node_path)
	
	if not _spawn_area or not _spawn_timer:
		Logger.priority(LOG_CAT, "Ruta de SpawnArea o SpawnTimer no válida.", self)
		_can_spawn = false
		set_process(false)
		set_physics_process(false)
		return
		
	for child in _spawn_area.get_children():
		if child is CollisionShape2D:
			_spawn_collision_shape = child
			break
			
	if not _spawn_collision_shape:
		Logger.priority(LOG_CAT, "No se encontró un CollisionShape2D dentro de SpawnArea.", self)
		return
		
	_spawn_timer.wait_time = time_interval
	_spawn_timer.one_shot = false
	_spawn_timer.autostart = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	match spawn_mode:
		SpawnMode.TIMER:
			_spawn_timer.wait_time = time_interval
			_spawn_timer.start(initial_delay if initial_delay > 0 else time_interval)
			
		SpawnMode.AT_START:
			for i in range(spawn_count):
				spawn_entity()
				
		SpawnMode.MAINTAIN:
			for i in range(spawn_count):
				spawn_entity()
				
			_spawn_timer.wait_time = time_interval
			_spawn_timer.start(initial_delay if initial_delay > 0 else time_interval)
			
		SpawnMode.ON_EVENT:
			pass


func update_spawn_config(new_spawn_count: int, new_max_instances: int, new_time_interval: float):
	spawn_count = new_spawn_count
	max_instances_per_spawner = new_max_instances
	time_interval = new_time_interval
	
	if _spawn_timer:
		_spawn_timer.wait_time = time_interval

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not scene_to_spawn:
		warnings.append("¡No se ha asignado una 'Scene To Spawn'!")
		
	var area = get_node_or_null(spawn_area_node_path)
	if not area or not area is Area2D:
		warnings.append("¡'Spawn Area Node Path' no apunta a un Area2D válido!")
	elif area:
		var found_shape = false
		for child in area.get_children():
			if child is CollisionShape2D:
				found_shape = true
				break
		if not found_shape:
			warnings.append("¡El Area2D no tiene un CollisionShape2D como hijo!")
			
	var timer = get_node_or_null(spawn_timer_node_path)
	if not timer or not timer is Timer:
		warnings.append("¡'Spawn Timer Node Path' no apunta a un Timer válido!")
		
	if check_collision and collision_mask == 0:
		warnings.append("¡Collision Mask está en 0! No se detectarán colisiones")
		
	return warnings
	
func trigger_spawn(count: int = 1):
	if not _can_spawn: return
	
	for i in range(count):
		spawn_entity()
	
func spawn_entity():
	print("Intentando spawnear entidad...")
	if not _can_spawn: return
	if not scene_to_spawn: 
		Logger.priority(LOG_CAT, "No hay 'scene_to_spawn' configurada.", self)
		return

	if max_instances_per_spawner > 0 and _active_instances.size() >= max_instances_per_spawner:
		Logger.priority(LOG_CAT, "Límite de instancias alcanzado.", self)
		return

	var instance = scene_to_spawn.instantiate()
	var spawn_position = Vector2.ZERO
	
	var valid_position = false
	var attempts = 0
	
	while not valid_position and attempts < max_spawn_attempts:
		spawn_position = get_random_position_in_area()
		
		if check_collision and is_position_colliding(spawn_position):
			attempts += 1
		else:
			valid_position = true
	
	if not valid_position:
		Logger.priority(LOG_CAT, "No se encontró posición válida después de " + str(attempts) + " intentos", self)
		Logger.warning(LOG_CAT, "Considera aumentar el área de spawn o reducir obstáculos", self)
		instance.queue_free()
		_can_spawn = true
		return
	
	if instance is Node2D:
		instance.global_position = spawn_position
	else:
		Logger.priority(LOG_CAT, "La escena instanciada no es Node2D, no se puede posicionar.", self)

	get_parent().add_child(instance)

	if not group_for_spawned_entities.is_empty():
		instance.add_to_group(group_for_spawned_entities)

	_active_instances.append(instance)

	instance.tree_exited.connect(_on_instance_destroyed.bind(instance))
	
	Logger.priority(LOG_CAT, "Entidad generada en" + str(spawn_position), self)

func is_position_colliding(position: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	
	query.position = position
	query.collision_mask = collision_mask
	query.exclude = []  # Puedes excluir objetos específicos si es necesario
	
	var results = space_state.intersect_point(query, 1)
	return results.size() > 0

func get_random_position_in_area() -> Vector2:
	if not _spawn_collision_shape or not _spawn_collision_shape.shape:
		Logger.priority(LOG_CAT, "No hay forma de colisión para calcular posición. Usando posición del Spawner.", self)
		return global_position

	var shape = _spawn_collision_shape.shape
	var area_transform = _spawn_collision_shape.global_transform

	if shape is RectangleShape2D:
		var extents = shape.size / 2.0
		var rand_x = randf_range(-extents.x, extents.x)
		var rand_y = randf_range(-extents.y, extents.y)
		return area_transform * Vector2(rand_x, rand_y)

	elif shape is CircleShape2D:
		var radius = shape.radius
		var rand_angle = randf_range(0, TAU) # TAU = 2 * PI
		var rand_radius = randf_range(0, radius)
		var point = Vector2(cos(rand_angle), sin(rand_angle)) * rand_radius
		return area_transform * point
		

	else:
		Logger.priority(LOG_CAT, "Forma de colisión no soportada. Usando posición del Spawner.", self)
		return global_position
	
func _on_spawn_timer_timeout():
	if not _can_spawn: return

	match spawn_mode:
		SpawnMode.TIMER:
			spawn_entity()
		
		SpawnMode.MAINTAIN:
			if _active_instances.size() < max_instances_per_spawner:
				spawn_entity()
	
func _on_instance_destroyed(instance: Node):
	var index = _active_instances.find(instance)
	if index != -1:
		_active_instances.remove_at(index)
		Logger.priority(LOG_CAT, "Instancia destruida, conteo actual: " + str(_active_instances.size()), self)
		
func reset_to_defaults():
	time_interval = default_time_interval
	max_instances_per_spawner = default_max_instances
	spawn_count = default_spawn_count

	if _spawn_timer:
		_spawn_timer.wait_time = time_interval
