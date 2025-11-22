extends Node

# --- НАЛАШТУВАННЯ ---
enum Difficulty { EASY, HARD }
var current_difficulty = Difficulty.HARD
var max_health = 1

# --- ЛУТ (Те, що ми випадково видалили) ---
var health_potion = preload("res://health_potion.tscn")
var damage_up = preload("res://damage_up.tscn")

func get_random_loot():
	var roll = randf() # 0.0 to 1.0
	if roll < 0.05: 
		return damage_up
	elif roll < 0.20:
		return health_potion
	return null

# --- ЗБЕРЕЖЕННЯ ---
const SAVE_PATH = "user://savegame.json"

var save_data = {
	"high_scores": [],
	"achievements": {
		"first_blood": false,
		"survivor": false,
		"boss_killer": false
	}
}

signal achievement_unlocked(title)

func _ready():
	load_game()

# --- ЛОГІКА АЧІВОК ---
func unlock_achievement(key, title_text):
	if not save_data["achievements"].has(key) or save_data["achievements"][key] == false:
		save_data["achievements"][key] = true
		save_game()
		emit_signal("achievement_unlocked", title_text)
		print("ACHIEVEMENT UNLOCKED: ", title_text)

# --- ЛОГІКА СКОР-БОРДА ---
func add_score(new_score):
	save_data["high_scores"].append(new_score)
	save_data["high_scores"].sort()
	save_data["high_scores"].reverse()
	
	if save_data["high_scores"].size() > 5:
		save_data["high_scores"].resize(5)
		
	save_game()

# --- ФУНКЦІЇ ЗБЕРЕЖЕННЯ ---
func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json_string = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var loaded_data = json.get_data()
			if loaded_data.has("high_scores"): save_data["high_scores"] = loaded_data["high_scores"]
			if loaded_data.has("achievements"): 
				for k in loaded_data["achievements"]:
					save_data["achievements"][k] = loaded_data["achievements"][k]

# --- СКЛАДНІСТЬ ---
func set_difficulty(difficulty_level):
	current_difficulty = difficulty_level
	if current_difficulty == Difficulty.EASY:
		max_health = 3
	else:
		max_health = 1

func reset_progress():
	save_data = {
		"high_scores": [],
		"achievements": {
			"first_blood": false,
			"survivor": false,
			"boss_killer": false
		}
	}
	save_game()
	print("Progress Reset!")
