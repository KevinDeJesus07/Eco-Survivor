extends Control

@onready var name_label: Label = $Name
@onready var health: ProgressBar = $Health
@onready var health_text: Label = $Health/HealthText

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
		if is_instance_valid(health_text):
			health_text.text = str(owner.hp)
		
	visible = true
	Logger.priority(LOG_CAT, "HUD inicializado para: " + str(owner.name), self)
	
	if owner:
		owner.connect("display_name_changed", self._on_display_name_changed)
		update_name(owner.display_name)

func update_name(new_name: String):
	if is_instance_valid(name_label):
		name_label.text = new_name
	Logger.debug(LOG_CAT, "HUD actualizado con nombre: %s" % new_name, self)

# Señal cuando cambia el nombre
func _on_display_name_changed(new_name):
	update_name(new_name)

"""
func update_health(new_hp: int, new_max_hp: int = -1):
	if is_instance_valid(health):
		var actual_max_hp = GameManager.player_max_hp
		
		if new_max_hp > 0:
			actual_max_hp = new_max_hp
			GameManager.player_max_hp = new_max_hp
			
		health.value = new_hp
		health.max_value = actual_max_hp	
			
		if is_instance_valid(health_text):
			health_text.text = str(new_hp)
	else:
		Logger.priority(LOG_CAT, "Instancia no válida de Health", self)
"""
func update_health(new_hp: int, new_max_hp: int = -1):
	if is_instance_valid(health):
		if new_max_hp > 0:
			set_max_health(new_max_hp)
		
		set_current_health(new_hp)
	else:
		Logger.priority(LOG_CAT, "Instancia no válida de Health", self)

func set_max_health(max_value: int):
	health.max_value = max_value
	health.queue_redraw()
	health.value = health.value - 0.01
	health.value = health.value + 0.01

func set_current_health(value: int):
	health.value = value
	if is_instance_valid(health_text):
		health_text.text = str(value)
