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
var current_health = 1 
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
	"music_volume": 1.0,
	"resolution_index": 0,    # Індекс випадаючого списку (0 = Native)
	"graphics_quality": 1,    # 0 = Potato(Без тіней), 1 = Medium, 2 = Ultra
	"show_minimap": true,     # Чи показувати UI мінікарти
	"alt_music": false
}

# --- СИГНАЛИ ---
signal achievement_unlocked(title)

# --- ІНІЦІАЛІЗАЦІЯ ---
func _ready():
	load_settings()
	load_progress()
	apply_settings()

func apply_settings():
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

	# --- ЗАСТОСУВАННЯ НОВИХ НАЛАШТУВАНЬ ГРАФІКИ ---
	apply_graphics_quality()

# --- ФУНКЦІЯ ГРАФІКИ (ОПТИМІЗАЦІЯ) ---
func apply_graphics_quality():
	var quality = settings_data.get("graphics_quality", 1)
	
	var player_light = null
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_light = players[0].get_node_or_null("PointLight2D")
		
	var canvas_modulate = get_tree().root.get_node_or_null("Map/CanvasModulate")
	
	if quality == 0:
		# --- POTATO MODE ---
		ProjectSettings.set_setting("rendering/2d/shadow_atlas/size", 0)
		ProjectSettings.set_setting("rendering/2d/shadow_atlas/size.mobile", 0)
		
		# 1. ПОВНІСТЮ ВИМИКАЄМО СВІТЛО! (Немає світла = немає прорахунку Нормал-мап)
		if player_light: 
			player_light.enabled = false 
		
		# 2. Робимо карту ідеально світлою
		if canvas_modulate: 
			canvas_modulate.color = Color(1.0, 1.0, 1.0, 1.0) 
		
	elif quality == 1:
		# --- MEDIUM MODE ---
		ProjectSettings.set_setting("rendering/2d/shadow_atlas/size", 1024)
		ProjectSettings.set_setting("rendering/2d/shadow_atlas/size.mobile", 512)
		
		# ПОВЕРТАЄМО СВІТЛО ТА ТІНІ
		if player_light: 
			player_light.enabled = true
			player_light.shadow_enabled = true
			
		if canvas_modulate: 
			canvas_modulate.color = Color(0.15, 0.15, 0.2, 1.0) # Твій колір темряви
		
	elif quality == 2:
		# --- ULTRA MODE ---
		ProjectSettings.set_setting("rendering/2d/shadow_atlas/size", 4096)
		ProjectSettings.set_setting("rendering/2d/shadow_atlas/size.mobile", 2048)
		
		# ПОВЕРТАЄМО СВІТЛО ТА ТІНІ
		if player_light: 
			player_light.enabled = true
			player_light.shadow_enabled = true
			
		if canvas_modulate: 
			canvas_modulate.color = Color(0.15, 0.15, 0.2, 1.0)

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
		max_health = 5
	else:
		base_health = 1
		max_health = 3

func go_to_next_level():
	current_level += 1
	get_tree().reload_current_scene()

func get_difficulty_multiplier() -> float:
	return 1.0 + (current_level - 1) * 0.1

# --- ЛОГІКА ЛУТУ ---
func get_random_loot():
	var roll = randf()
	if roll < 0.05: return damage_up
	elif roll < 0.10: return speed_up
	elif roll < 0.20: return shield
	elif roll < 0.35: return health_potion
	return null

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
			var data = json.get_data()
			# Зливаємо старі налаштування з новими, щоб не ламати сейви
			for key in data.keys():
				settings_data[key] = data[key]

func get_high_scores() -> Array:
	return progress_data.high_scores

func get_achievements_data() -> Dictionary:
	return progress_data.achievements

func reset_progress():
	progress_data = {
		"high_scores": [],
		"achievements": { "first_blood": false, "survivor": false, "boss_killer": false }
	}
	save_progress()
	print("Progress Reset!")
