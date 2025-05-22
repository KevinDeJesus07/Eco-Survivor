extends Control

@onready var name_label: Label = $Name
@onready var health: ProgressBar = $Health

const LOG_CAT: String = "ENTITY_HUD"

var entity: BaseEntity = null

func _ready() -> void:
	visible = false
	if not is_instance_valid(name_label):
		Logger.priority(LOG_CAT, "NameLabel no encontrado!", self)
		
	if not is_instance_valid(health):
		Logger.priority(LOG_CAT, "HealthBar no encontrado!", self)
		
func initialize_hud(owner: BaseEntity):
	if not is_instance_valid(owner):
		Logger.priority(LOG_CAT, "Intento de inicializar HUD con entidad inválida.", self)
		visible = false
		return
	
	entity = owner
	
	if is_instance_valid(name_label):
		name_label.text = owner.display_name
		
	if is_instance_valid(health):
		health.max_value = owner.max_hp
		health.value = owner.hp
		
	visible = true
	Logger.priority(LOG_CAT, "HUD inicializado para: " + str(owner.name), self)
	
func update_health(new_hp: int):
	if is_instance_valid(health):
		health.value = new_hp
	else:
		Logger.priority(LOG_CAT, "Instancia no válida de Health", self)
