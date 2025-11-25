extends Node

# --- КОНСТАНТИ ---
const PROGRESS_PATH = "user://progress.json"
const SETTINGS_PATH = "user://settings.json"

# --- НАЛАШТУВАННЯ ГРИ ---
enum Difficulty { EASY, HARD }
var current_difficulty = Difficulty.HARD

# --- СТАН ГРАВЦЯ МІЖ РІВНЯМИ ---
var base_health = 1
var max_health = 1
var current_health = 1 # Здоров'я, яке переноситься на наступний рівень
var current_score = 0
var current_level = 1

# --- ЛУТ ---
var health_potion = preload("res://health_potion.tscn")
var damage_up = preload("res://damage_up.tscn")
var speed_up = preload("res://speed_up.tscn")
var shield = preload("res://shield.tscn")

# --- ЗБЕРІГАННЯ ДАНИХ ---
var progress_data = {
	"high_scores": [],
	"achievements": {
		"first_blood": false,
		"survivor": false,
		"boss_killer": false
	}
}

var settings_data = {
	"fullscreen": false,
	"vsync": true,
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"music_volume": 1.0
}

# --- СИГНАЛИ ---
signal achievement_unlocked(title)

# --- ІНІЦІАЛІЗАЦІЯ ---
func _ready():
	load_settings()
	load_progress()
	apply_settings()

func apply_settings():
	# Застосовуємо завантажені налаштування
	# Гучність
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(settings_data.master_volume))
	
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(settings_data.sfx_volume))
	
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(settings_data.music_volume))

	# V-Sync
	if settings_data.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# Повний екран
	if settings_data.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# --- ЛОГІКА ІГРОВОГО ЦИКЛУ ---
func start_new_game(difficulty_level):
	set_difficulty(difficulty_level)
	current_health = base_health
	current_score = 0
	current_level = 1
	get_tree().change_scene_to_file("res://main.tscn")

func set_difficulty(difficulty_level):
	current_difficulty = difficulty_level
	if current_difficulty == Difficulty.EASY:
		base_health = 3
		max_health = 4
	else:
		base_health = 1
		max_health = 1

func go_to_next_level():
	current_level += 1
	# Тут можна додати логіку підвищення складності
	get_tree().reload_current_scene()

func get_difficulty_multiplier() -> float:
	# Кожен рівень додає +10% до статів ворогів
	return 1.0 + (current_level - 1) * 0.1

# --- ЛОГІКА ЛУТУ ---
func get_random_loot():
	var roll = randf() # Випадкове число від 0.0 до 1.0
	
	# Шанси (можеш налаштувати як хочеш):
	# 5% - Damage Up
	# 5% - Speed Up
	# 10% - Shield
	# 15% - Health Potion
	# 65% - Нічого
	
	if roll < 0.05:
		return damage_up
	elif roll < 0.10: # (0.05 + 0.05)
		return speed_up
	elif roll < 0.20: # (0.10 + 0.10)
		return shield
	elif roll < 0.35: # (0.20 + 0.15)
		return health_potion
	
	return null # Нічого не випало

# --- ЛОГІКА АЧІВОК ---
func unlock_achievement(key, title_text):
	if not progress_data.achievements.has(key) or progress_data.achievements[key] == false:
		progress_data.achievements[key] = true
		save_progress()
		emit_signal("achievement_unlocked", title_text)
		print("ACHIEVEMENT UNLOCKED: ", title_text)

# --- ЛОГІКА СКОР-БОРДА ---
func add_score_to_board(new_score):
	progress_data.high_scores.append(new_score)
	progress_data.high_scores.sort()
	progress_data.high_scores.reverse()
	
	if progress_data.high_scores.size() > 5:
		progress_data.high_scores.resize(5)
	
	save_progress()

# --- ФУНКЦІЇ ЗБЕРЕЖЕННЯ ---
func save_progress():
	var file = FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(progress_data))

func load_progress():
	if FileAccess.file_exists(PROGRESS_PATH):
		var file = FileAccess.open(PROGRESS_PATH, FileAccess.READ)
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			var data = json.get_data()
			# Зливаємо дані, щоб не ламати сейв, якщо додали нові ачівки
			if data.has("high_scores"): progress_data.high_scores = data.high_scores
			if data.has("achievements"):
				for key in data.achievements:
					progress_data.achievements[key] = data.achievements[key]

func save_settings():
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(settings_data))

func load_settings():
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			settings_data = json.get_data()

func get_high_scores() -> Array:
	return progress_data.high_scores

# Додай цю функцію в GameManager.gd
func get_achievements_data() -> Dictionary:
	return progress_data.achievements

func reset_progress():
	progress_data = {
		"high_scores": [],
		"achievements": { "first_blood": false, "survivor": false, "boss_killer": false }
	}
	save_progress()
	print("Progress Reset!")
