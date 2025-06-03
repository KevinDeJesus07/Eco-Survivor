extends Node

var player_gender: String = "male"
var player_max_hp: int
var player_hp: int
var player_speed: float

var total_score: int = 0

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

func add_score(amount: int):
	total_score += amount
	emit_signal("score_changed", total_score)

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
		
