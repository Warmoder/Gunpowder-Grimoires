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
var saved_weapon_index: int = 0
var saved_has_shield: bool = false
var saved_speed_time_left: float = 0.0
var saved_damage_time_left: float = 0.0
var saved_heal_cooldown: float = 0.0
var saved_magic_cooldown: float = 0.0

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
	"graphics_quality": 1,    # 0 = Potato, 1 = Medium, 2 = Ultra, 3 = Custom
	"wall_mode": 0,           # 0 = Monolith (Full Rock), 1 = Fast (Perimeter)
	"show_minimap": true,     # Чи показувати UI мінікарти
	"show_fps": true,         # Чи показувати FPS оверлей
	"alt_music": false,
	"brightness": 1.0,        # 0.5 - 2.5 (множник яскравості темряви)
	"normal_maps": true,      # 2.5D рельєф каменю
	"shadows": true,          # Динамічні тіні
	"lanterns_light": true,   # Світло настінних ліхтарів
	"max_fps": 60,            # 60, 120, 0 (без обмежень)
	"show_damage_numbers": true,
	"damage_numbers_scale": 1.0,
	"keybindings": {}
}

const DEFAULT_KEYBINDINGS = {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"magic_heal": KEY_Q,
	"magic_random": KEY_E,
	"switch_weapon": KEY_TAB,
	"toggle_minimap": KEY_M,
	"toggle_fullscreen": KEY_F11
}

var _floating_font: Font = preload("res://text_style.ttf")

# --- FPS ОВЕРЛЕЙ ТА СТАН ---
var fps_layer: CanvasLayer
var fps_label: Label
var fps_timer: float = 0.0

# --- СИГНАЛИ ---
signal achievement_unlocked(title)

# --- ІНІЦІАЛІЗАЦІЯ ---
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	DisplayServer.window_set_title("Gunpowder & Grimoires")
	load_settings()
	load_progress()
	apply_settings()
	_setup_fps_overlay()

func _setup_fps_overlay():
	fps_layer = CanvasLayer.new()
	fps_layer.layer = 999
	fps_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fps_layer)
	
	fps_label = Label.new()
	fps_label.name = "FpsLabel"
	fps_label.anchors_preset = Control.PRESET_TOP_RIGHT
	fps_label.anchor_left = 1.0
	fps_label.anchor_right = 1.0
	fps_label.anchor_top = 0.0
	fps_label.anchor_bottom = 0.0
	fps_label.offset_left = -240.0
	fps_label.offset_top = 16.0
	fps_label.offset_right = -20.0
	fps_label.offset_bottom = 46.0
	fps_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var font = load("res://text_style.ttf")
	if font:
		fps_label.add_theme_font_override("font", font)
	fps_label.add_theme_font_size_override("font_size", 18)
	fps_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.45, 0.95))
	fps_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	fps_label.add_theme_constant_override("shadow_offset_x", 1)
	fps_label.add_theme_constant_override("shadow_offset_y", 1)
	fps_label.add_theme_constant_override("outline_size", 2)
	fps_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	
	fps_layer.add_child(fps_label)
	update_fps_overlay_visibility()

func update_fps_overlay_visibility():
	if fps_layer:
		fps_layer.visible = settings_data.get("show_fps", true)

func _process(delta):
	fps_timer += delta
	if fps_timer >= 0.25:
		fps_timer = 0.0
		var current_fps = Engine.get_frames_per_second()
		var rounded_fps = roundi(current_fps)
		# Реальний час кадру — з Engine, а не з delta (delta тут ~250ms через таймер)
		var frame_time_ms = (1000.0 / float(current_fps)) if current_fps > 0 else 0.0
		
		if fps_label and fps_layer and fps_layer.visible:
			fps_label.text = "FPS: %d | %.1f ms" % [rounded_fps, frame_time_ms]
			if rounded_fps >= 55:
				fps_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.45, 0.95))
			elif rounded_fps >= 30:
				fps_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 0.95))
			else:
				fps_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 0.95))

# Реєстрація допоміжних PointLight2D (вороги, лут, скрині, портал)
func register_aux_light(light: PointLight2D, default_height: float = 26.0):
	if not light: return
	light.add_to_group("aux_lights")
	var quality = settings_data.get("graphics_quality", 1)
	var normal_maps = settings_data.get("normal_maps", true)
	light.height = default_height if normal_maps else 0.0
	var enabler = light.get_node_or_null("VisibleOnScreenEnabler2D")
	if enabler:
		enabler.screen_entered.connect(func():
			if is_instance_valid(light) and settings_data.get("graphics_quality", 1) != 0:
				light.enabled = true
		)
		enabler.screen_exited.connect(func():
			if is_instance_valid(light):
				light.enabled = false
		)
		light.enabled = (quality != 0 and enabler.is_on_screen())
	else:
		light.enabled = (quality != 0)

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
	
	# Повний екран (Exclusive Fullscreen обходить DWM-композитор Windows для кращого VSync/CapFrameX)
	if settings_data.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Застосування графіки, хоткеїв та UI
	apply_detailed_graphics()
	apply_keybindings()
	update_minimap_visibility()

func apply_keybindings():
	var saved = settings_data.get("keybindings", {})
	if not (saved is Dictionary):
		saved = {}
	for action in DEFAULT_KEYBINDINGS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var keycode: int = int(saved.get(action, DEFAULT_KEYBINDINGS[action]))
		# Видаляємо старі клавіатурні прив'язки, залишаючи мишу/геймпад якщо є
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)
		var new_ev = InputEventKey.new()
		new_ev.physical_keycode = keycode
		InputMap.action_add_event(action, new_ev)

func rebind_action(action: String, physical_keycode: int):
	if not (settings_data.get("keybindings") is Dictionary):
		settings_data["keybindings"] = {}
	settings_data["keybindings"][action] = physical_keycode
	apply_keybindings()
	save_settings()

func reset_keybindings():
	settings_data["keybindings"] = {}
	apply_keybindings()
	save_settings()

func get_action_keycode(action: String) -> int:
	var saved = settings_data.get("keybindings", {})
	if saved is Dictionary and saved.has(action):
		return int(saved[action])
	return int(DEFAULT_KEYBINDINGS.get(action, KEY_NONE))

func update_minimap_visibility():
	var show_map = settings_data.get("show_minimap", true)
	var scene = get_tree().current_scene
	if scene and scene.has_node("UI/PanelContainer"):
		scene.get_node("UI/PanelContainer").visible = show_map

# --- ПЛАВАЮЧИЙ ТЕКСТ (ЦИФРИ УРОНУ ТА ПІДБІР ЛУТУ) ---
func spawn_floating_text(world_pos: Vector2, text: String, color: Color = Color.WHITE, text_scale: float = 1.0):
	var scene = get_tree().current_scene
	if not scene: return
	var lbl = Label.new()
	lbl.text = text
	lbl.z_index = 50
	lbl.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _floating_font:
		lbl.add_theme_font_override("font", _floating_font)
	var f_size = clampi(roundi(18.0 * text_scale), 10, 40)
	lbl.add_theme_font_size_override("font_size", f_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.global_position = world_pos + Vector2(randf_range(-14.0, 14.0), -26.0)
	scene.add_child(lbl)
	
	var tween = lbl.create_tween().set_parallel(true)
	tween.tween_property(lbl, "global_position:y", lbl.global_position.y - 36.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)

func spawn_damage_number(world_pos: Vector2, amount: float, is_crit: bool = false):
	if not settings_data.get("show_damage_numbers", true):
		return
	var dmg_scale = float(settings_data.get("damage_numbers_scale", 1.0))
	var txt = str(int(amount)) if is_equal_approx(amount, round(amount)) else ("%.1f" % amount)
	var col = Color(1.0, 0.85, 0.25) if is_crit else Color(1.0, 0.95, 0.9)
	spawn_floating_text(world_pos, txt, col, dmg_scale)

# --- ВУЗЛИ ОСВІТЛЕННЯ ---
func get_canvas_modulate() -> CanvasModulate:
	var list = get_tree().get_nodes_in_group("canvas_modulate")
	if list.size() > 0 and list[0] is CanvasModulate:
		return list[0]
	var scene = get_tree().current_scene
	if scene:
		if scene is CanvasModulate:
			return scene
		var cm = scene.get_node_or_null("CanvasModulate")
		if cm and cm is CanvasModulate:
			return cm
	return null

func get_player_light() -> PointLight2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0].get_node_or_null("PointLight2D")
	return null

# --- ФУНКЦІЯ ДЕТАЛЬНОЇ ГРАФІКИ ---
func apply_detailed_graphics():
	# 1. Ліміт FPS
	var max_fps = settings_data.get("max_fps", 60)
	Engine.max_fps = max_fps
	
	var quality = settings_data.get("graphics_quality", 1)
	var normal_maps = settings_data.get("normal_maps", true)
	var shadows = settings_data.get("shadows", true)
	var lanterns_light = settings_data.get("lanterns_light", true)
	var brightness = settings_data.get("brightness", 1.0)
	
	# 2. CanvasModulate (Яскравість темряви підземелля)
	var canvas_modulate = get_canvas_modulate()
	if canvas_modulate:
		if quality == 0:
			canvas_modulate.color = Color(1.0, 1.0, 1.0, 1.0)
		else:
			var base_dark = Color(0.11, 0.11, 0.19, 1.0)
			canvas_modulate.color = Color(
				clampf(base_dark.r * brightness, 0.0, 1.0),
				clampf(base_dark.g * brightness, 0.0, 1.0),
				clampf(base_dark.b * brightness, 0.0, 1.0),
				1.0
			)
			
	# 3. Світло гравця (2.5D нормал-мапи та тіні)
	var player_light = get_player_light()
	if player_light:
		if quality == 0:
			player_light.enabled = false
		else:
			player_light.enabled = true
			player_light.shadow_enabled = shadows
			player_light.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5 if quality == 2 else PointLight2D.SHADOW_FILTER_NONE
			player_light.height = 26.0 if normal_maps else 0.0
			player_light.energy = 1.4
			player_light.scale = Vector2(3.8, 3.8)
			
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var shield_light = players[0].get_node_or_null("ShieldSprite/PointLight2D")
		if shield_light:
			shield_light.enabled = (quality != 0)
			shield_light.height = 26.0 if normal_maps else 0.0
			# Щит знаходиться в тій же точці, що й основне світло гравця — друга shadow map не потрібна
			shield_light.shadow_enabled = false
			
	# 4. Ліхтарі
	var lanterns = get_tree().get_nodes_in_group("lanterns")
	for lantern in lanterns:
		if lantern.has_method("update_graphics_settings"):
			lantern.update_graphics_settings()
		else:
			var l = lantern.get_node_or_null("PointLight2D")
			if l:
				l.height = 59.0 if normal_maps else 0.0
				l.enabled = (quality != 0 and lanterns_light)
				
	# 5. Допоміжні джерела світла (вороги, бос) — вимикаємо на Potato/Low
	var aux_lights = get_tree().get_nodes_in_group("aux_lights")
	for light in aux_lights:
		if light is PointLight2D:
			light.height = 26.0 if normal_maps else 0.0
			if quality == 0:
				light.enabled = false
			else:
				var enabler = light.get_node_or_null("VisibleOnScreenEnabler2D")
				light.enabled = enabler.is_on_screen() if enabler else true

func apply_graphics_quality():
	apply_detailed_graphics()

func set_preset(preset_index: int):
	settings_data["graphics_quality"] = preset_index
	match preset_index:
		0: # Low / Potato
			settings_data["normal_maps"] = false
			settings_data["shadows"] = false
			settings_data["lanterns_light"] = false
			settings_data["wall_mode"] = 1
		1: # Medium / Balanced
			settings_data["normal_maps"] = true
			settings_data["shadows"] = true
			settings_data["lanterns_light"] = true
			settings_data["wall_mode"] = 0
		2: # Ultra / 2.5D Full
			settings_data["normal_maps"] = true
			settings_data["shadows"] = true
			settings_data["lanterns_light"] = true
			settings_data["wall_mode"] = 0
		3: # Custom
			pass
	apply_detailed_graphics()
	save_settings()

# --- ЛОГІКА ІГРОВОГО ЦИКЛУ ---
func start_new_game(difficulty_level):
	set_difficulty(difficulty_level)
	current_health = base_health
	current_score = 0
	current_level = 1
	saved_weapon_index = 0
	saved_has_shield = false
	saved_speed_time_left = 0.0
	saved_damage_time_left = 0.0
	saved_heal_cooldown = 0.0
	saved_magic_cooldown = 0.0
	get_tree().change_scene_to_file("res://main.tscn")

func save_player_state():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	current_health = player.current_health
	saved_weapon_index = player.current_weapon_index
	saved_has_shield = player.has_shield
	saved_speed_time_left = maxf(0.0, player.speed_time_left)
	saved_damage_time_left = maxf(0.0, player.damage_time_left)
	saved_heal_cooldown = maxf(0.0, player.heal_cooldown)
	saved_magic_cooldown = maxf(0.0, player.magic_cooldown)

func set_difficulty(difficulty_level):
	current_difficulty = difficulty_level
	if current_difficulty == Difficulty.EASY:
		base_health = 3
		max_health = 5
	else:
		base_health = 1
		max_health = 3

func go_to_next_level():
	save_player_state()
	current_level += 1
	get_tree().reload_current_scene()

func get_difficulty_multiplier() -> float:
	# Трохи швидша прогресія (+20% за кожен рівень)
	return 1.0 + (current_level - 1) * 0.2

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
	if not file:
		push_error("GameManager: не вдалося зберегти прогрес (код: %d)" % FileAccess.get_open_error())
		return
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
	if not file:
		push_error("GameManager: не вдалося зберегти налаштування (код: %d)" % FileAccess.get_open_error())
		return
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
