extends Node

# --- НАЛАШТУВАННЯ ---
enum Difficulty { EASY, HARD }
var current_difficulty = Difficulty.HARD
var base_health = 1 # Скільки життів на старті
var max_health = 1  # Абсолютний максимум

# --- ЛУТ ---
var health_potion = preload("res://health_potion.tscn")
var damage_up = preload("res://damage_up.tscn")

func get_random_loot():
	var roll = randf()
	if roll < 0.05: return damage_up
	elif roll < 0.20: return health_potion
	return null

# --- ЗБЕРЕЖЕННЯ ---
const SAVE_PATH = "user://savegame.json"

var save_data = {
	"high_scores": [],
	"achievements": {
		"first_blood": false,
		"survivor": false,
		"boss_killer": false
	},
	"music_volume": 1.0 # <--- НОВЕ: Значення від 0.0 до 1.0 (за замовчуванням повна гучність)
}

signal achievement_unlocked(title)

func _ready():
	load_game()
	# <--- НОВЕ: Одразу застосовуємо завантажену гучність при старті гри
	apply_volume(save_data["music_volume"])

# --- ЛОГІКА ГУЧНОСТІ (НОВЕ) ---
func set_volume(value):
	# 1. Оновлюємо дані
	save_data["music_volume"] = value
	# 2. Застосовуємо звук
	apply_volume(value)
	# 3. Зберігаємо файл
	save_game()

func apply_volume(value):
	# Знаходимо індекс шини "Master" (Головна гучність)
	var bus_index = AudioServer.get_bus_index("Master")
	
	# Godot використовує Децибели (dB), а слайдери - лінійні числа (0-1).
	# Функція linear_to_db конвертує 0.5 в -6dB, 0 в -нескінченність і т.д.
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

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
			
			# <--- НОВЕ: Завантажуємо гучність, якщо вона є у файлі
			if loaded_data.has("music_volume"):
				save_data["music_volume"] = loaded_data["music_volume"]

# --- СКЛАДНІСТЬ ---
func set_difficulty(difficulty_level):
	current_difficulty = difficulty_level
	if current_difficulty == Difficulty.EASY:
		base_health = 3
		max_health = 4 # На легкому режимі можна мати до 4 ХП
	else: # HARD
		base_health = 1
		max_health = 1 # На складному - ніяких бонусів

func reset_progress():
	# Оновлюємо словник, але гучність можна залишити або скинути (тут скидаємо на 1.0)
	save_data = {
		"high_scores": [],
		"achievements": {
			"first_blood": false,
			"survivor": false,
			"boss_killer": false
		},
		"music_volume": 1.0
	}
	save_game()
	apply_volume(1.0) # Скидаємо звук
	print("Progress Reset!")
