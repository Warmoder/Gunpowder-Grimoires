extends Node2D

# Сюди ми перетягнемо сцену ворога
@export var enemy_scenes: Array[PackedScene]
# Таймер для спавну
@onready var spawn_timer = $SpawnTimer
# Змінна для зберігання рахунку
var score = 0
@onready var dungeon_generator = $DungeonGenerator
var valid_spawn_points: Array[Vector2i] = []
@onready var score_label = $UI/ScoreLabel
@onready var pause_menu = $PauseMenu
@export var game_over_scene: PackedScene
@export var boss_scene: PackedScene
@export var teleporter_scene: PackedScene
@export var chest_scene: PackedScene
@export var transition_scene: PackedScene
@export var loading_screen_scene: PackedScene
var current_loading_screen = null
var current_transition = null
@onready var player = $Player
@onready var health_bar = $UI/HealthBar
@onready var stats_panel = $UI/StatsPanel
@onready var damage_overlay = $UI/DamageOverlay
@onready var pause_button = $UI/PauseButton
@onready var parallax_bg = get_node_or_null("Parallax2D")
@onready var canvas_modulate = get_node_or_null("CanvasModulate")

func _ready():
	if canvas_modulate:
		canvas_modulate.add_to_group("canvas_modulate")
	GameManager.apply_detailed_graphics()
	GameManager.update_minimap_visibility()
	
	# Встановлюємо видимість фону залежно від режиму стін (у Fast Perimeter вимикаємо космос)
	var wall_mode = GameManager.settings_data.get("wall_mode", 0)
	if parallax_bg:
		parallax_bg.visible = (wall_mode == 0)
	
	# 1. ПОКАЗУЄМО ТІЛЬКИ ЕКРАН "ГЕНЕРАЦІЇ"
	if loading_screen_scene:
		current_loading_screen = loading_screen_scene.instantiate()
		add_child(current_loading_screen)
	
	# Даємо рушію 1 кадр, щоб відмалювати текст "Generating..."
	await get_tree().process_frame
	
	# Прогрів шейдерів куль та часток для усунення фрізу на першому пострілі
	await _prewarm_shaders()
	
	# 2. Підключаємось до генератора і запускаємо потік
	dungeon_generator.generation_finished.connect(_on_map_generated)
	dungeon_generator.generate_map()

func _prewarm_shaders():
	var warmup_container = Node2D.new()
	warmup_container.modulate = Color(1, 1, 1, 0.01) # Рендериться GPU під заставкою
	add_child(warmup_container)
	
	var scenes_to_prewarm = [
		player.bullet_scene,
		player.shotgun_pellet_scene,
		player.rifle_bullet_scene,
		player.muzzle_flash_scene,
		player.explosion_scene
	]
	
	for scn in scenes_to_prewarm:
		if scn:
			var inst = scn.instantiate()
			warmup_container.add_child(inst)
			inst.position = Vector2(640, 360)
			if inst is GPUParticles2D:
				inst.emitting = true
				inst.restart()
			for child in inst.get_children():
				if child is GPUParticles2D:
					child.emitting = true
					child.restart()
	
	# Даємо GPU 1 кадр на компіляцію конвеєрів
	await get_tree().process_frame
	warmup_container.queue_free()

# Ця функція викличеться САМА, коли фоновий потік закінчить роботу
func _on_map_generated(floor_cells_result):
	valid_spawn_points = floor_cells_result
	
	var boss_room_center = dungeon_generator.create_boss_room()
	var boss_pos_pixel = dungeon_generator.floor_layer.map_to_local(boss_room_center)
	
	var teleporter = teleporter_scene.instantiate()
	teleporter.position = boss_pos_pixel
	add_child(teleporter)
	
	var boss = boss_scene.instantiate()
	boss.position = boss_pos_pixel
	boss.died.connect(teleporter.activate)
	add_child(boss)
	boss.reset_physics_interpolation()
	
	var spawn_rate = 2.0 / GameManager.get_difficulty_multiplier()
	spawn_rate = max(0.5, spawn_rate)
	
	spawn_timer.wait_time = spawn_rate
	spawn_timer.start()
	
	var player_start_tile = Vector2i(0, 0)
	var max_dist = 0.0
	
	for i in range(100):
		var test_tile = valid_spawn_points.pick_random()
		var dist = test_tile.distance_to(boss_room_center)
		
		if dist > max_dist:
			max_dist = dist
			player_start_tile = test_tile
	
	player.position = dungeon_generator.floor_layer.map_to_local(player_start_tile)
	player.reset_physics_interpolation()
	
	var touch_controls = $TouchControls
	
	if OS.get_name() == "Android":
		touch_controls.show()
		pause_button.show()
		if not pause_button.pressed.is_connected(_on_pause_button_pressed):
			pause_button.pressed.connect(_on_pause_button_pressed)
	else:
		touch_controls.hide()
		pause_button.hide()
	
	for i in range(5):
		spawn_chest()
	
	MusicManager.play_battle_music()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	score = GameManager.current_score
	score_label.text = "Lv.%d | Score: %d" % [GameManager.current_level, score]
	
	if not player.stats_updated.is_connected(stats_panel.update_stats):
		player.stats_updated.connect(stats_panel.update_stats)
		
	if not player.player_damaged.is_connected(damage_overlay.flash):
		player.player_damaged.connect(damage_overlay.flash)
		
	if not player.player_healed.is_connected(damage_overlay.flash_heal):
		player.player_healed.connect(damage_overlay.flash_heal)
		
	if not player.health_changed.is_connected(health_bar.update_health):
		player.health_changed.connect(health_bar.update_health)
		
	health_bar.update_health(GameManager.current_health, GameManager.max_health)

	# --- ФІНАЛ: ЗМІНА ЕКРАНІВ ---
	# Даємо рушію мікросекунду розставити об'єкти
	await get_tree().process_frame 
	
	# 1. Прибираємо технічний напис "Генерація..."
	if current_loading_screen:
		current_loading_screen.queue_free()
		current_loading_screen = null
		
	# 2. Створюємо кінематографічний напис "Level X" 
	current_transition = transition_scene.instantiate()
	add_child(current_transition)
	
	# 3. Запускаємо його розчинення
	if current_transition.has_method("start_fade_out"):
		current_transition.start_fade_out()
		
	# Застосовуємо графічні налаштування до новостворених ліхтарів та сцени
	GameManager.apply_detailed_graphics()

const MAX_ENEMIES_PC = 35
const MAX_ENEMIES_MOBILE = 25

func get_max_enemies() -> int:
	return MAX_ENEMIES_MOBILE if OS.get_name() in ["Android", "iOS"] else MAX_ENEMIES_PC

func _on_spawn_timer_timeout():
	if valid_spawn_points.is_empty(): return
	
	# Перевірка ліміту ворогів для збереження CPU
	var enemy_count = 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is CharacterBody2D:
			enemy_count += 1
	if enemy_count >= get_max_enemies():
		return
	
	# Вибираємо випадкову плитку підлоги
	var random_tile = valid_spawn_points.pick_random()
	var spawn_pos = dungeon_generator.floor_layer.map_to_local(random_tile)
	
	# Перевірка дистанції (щоб не спавнились на голові)
	if spawn_pos.distance_squared_to(player.position) < 122500.0: # 350^2
		return
		
	# Інстанціюємо ворога тільки ПІСЛЯ перевірок (запобігає витоку пам'яті)
	var random_enemy_scene = enemy_scenes.pick_random()
	var enemy_instance = random_enemy_scene.instantiate()
	enemy_instance.global_position = spawn_pos
	enemy_instance.died.connect(_on_enemy_died)
	add_child(enemy_instance)
	enemy_instance.reset_physics_interpolation()

func _on_enemy_died():
	score += 1
	score_label.text = "Lv.%d | Score: %d" % [GameManager.current_level, score]
	GameManager.current_score = score
	
	# --- АЧІВКИ ---
	# 1. Перша кров
	if score == 1:
		GameManager.unlock_achievement("first_blood", "First Blood!")
		
	# 2. Виживший
	if score >= 10:
		GameManager.unlock_achievement("survivor", "Survivor (10+ Score)")

func game_over():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var crosshair = get_node_or_null("/root/CrosshairUi")
	if crosshair:
		crosshair.visible = false
	var game_over_instance = game_over_scene.instantiate()
	add_child(game_over_instance)
	# Чекаємо наступного кадру, щоб вузол гарантовано був готовий
	await get_tree().process_frame
	# Тепер, коли ми впевнені, що UI готовий, викликаємо функцію
	game_over_instance.show_final_score(score)
	get_tree().paused = true

func spawn_chest():
	if valid_spawn_points.is_empty(): return
	
	# Вибираємо випадкову точку ДО інстанціювання (запобігає витоку пам'яті)
	var random_tile = valid_spawn_points.pick_random()
	var spawn_pos = dungeon_generator.floor_layer.map_to_local(random_tile)
	
	# Перевірка: не спавнити поруч з гравцем (щоб не підібрав випадково)
	if spawn_pos.distance_squared_to(player.position) < 10000.0: # 100^2
		return
		
	var chest = chest_scene.instantiate()
	chest.position = spawn_pos
	add_child(chest)

# Цю функцію буде викликати наш глобальний InputManager
func toggle_pause():
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused
	
	var crosshair = get_node_or_null("/root/CrosshairUi")
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if crosshair:
			crosshair.visible = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		if crosshair:
			crosshair.visible = true

func _on_pause_button_pressed():
	toggle_pause()
