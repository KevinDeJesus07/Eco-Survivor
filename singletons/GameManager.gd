extends Node

var player_gender: String = "male"
var player_max_hp: int
var player_hp: int
var player_speed: float

var total_score: int = 0

var slime_spawn_multiplier := 1.0
var heal_spawn_multiplier := 1.0

var slime_increment := 0.2  # +20% por oleada
var heal_increment := 0.05  # +5% por oleada


var current_wave: int = 1
var enemy_speed_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0
var spawn_rate_multiplier: float = 1.0

var base_spawn_count := 1
var base_max_instances := 6
var base_time_interval := 5.0
var wave_number := 1  # actualizado en cada oleada

var player_speed_multiplier := 1.0
var player_max_hp_multiplier := 1.0
var player_upgrade_increment_hp := 0.1
var player_upgrade_increment_speed := 0.1

signal player_name_changed(new_name)
signal update_health(new_hp, max_hp)
signal score_changed(new_score)

var player_name: String = "Kevin":
	set(value):
		if value != player_name:
			player_name = value
			emit_signal("player_name_changed", value)  # Emitir señal al cambiar

func _ready():
	load_data()

func update_spawner_difficulty():
	for spawner in get_tree().get_nodes_in_group("spawners"):
		if spawner.has_method("update_spawn_config"):
			match spawner.spawner_type:
				"slime":
					var spawn_count = int(round(base_spawn_count * GameManager.slime_spawn_multiplier))
					var max_instances = int(round(base_max_instances * GameManager.slime_spawn_multiplier))
					var time_interval = max(base_time_interval - wave_number * 0.3, 1.0)
					
					spawner.update_spawn_config(spawn_count, max_instances, time_interval)
					
				"heal":
					var spawn_count = int(round(base_spawn_count * GameManager.heal_spawn_multiplier))
					var max_instances = int(round(base_max_instances * GameManager.heal_spawn_multiplier))
					var time_interval = max(10.0 - wave_number * 0.1, 2.0)
					
					spawner.update_spawn_config(spawn_count, max_instances, time_interval)

				"trash":
					spawner.update_spawn_config(
						1,  # spawn_count fijo
						5,  # max_instances fijo
						7.0  # intervalo fijo
					)

func next_wave():
	current_wave += 1
	
	enemy_speed_multiplier += 0.1
	enemy_damage_multiplier += 0.1
	spawn_rate_multiplier += 0.1
	
	slime_spawn_multiplier += slime_increment
	heal_spawn_multiplier += heal_increment
	
	enemy_speed_multiplier = round(enemy_speed_multiplier * 100) / 100.0
	enemy_damage_multiplier = round(enemy_damage_multiplier * 100) / 100.0
	spawn_rate_multiplier = round(spawn_rate_multiplier * 100) / 100.0
	
	for enemy in get_tree().get_nodes_in_group("enemigos"):
		if enemy.has_method("update_stats"):
			enemy.update_stats()
			
	update_spawner_difficulty()


func add_score(amount: int):
	total_score += amount
	emit_signal("score_changed", total_score)

func reset_difficulty():
	current_wave = 1
	enemy_speed_multiplier = 1.0
	enemy_damage_multiplier = 1.0
	spawn_rate_multiplier = 1.0

func save_data():
	var data = {
		"gender": player_gender,
		"display_name": player_name
	}
	var file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	file.store_var(data)

func load_data():
	if FileAccess.file_exists("user://savegame.dat"):
		var file = FileAccess.open("user://savegame.dat", FileAccess.READ)
		var data = file.get_var()
		player_gender = data.get("gender", "male")
		player_name = data.get("display_name", "Player")
		
