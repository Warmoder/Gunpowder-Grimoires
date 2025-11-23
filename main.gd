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
@onready var player = $Player
@onready var health_bar = $UI/HealthBar
@onready var stats_panel = $UI/StatsPanel

func _ready():
	# 1. Генерація карти
	valid_spawn_points = dungeon_generator.generate_map()
	
	# 2. Створення кімнати боса
	var boss_room_center = dungeon_generator.create_boss_room()
	var boss_pos_pixel = dungeon_generator.floor_layer.map_to_local(boss_room_center)
	
	# 3. Спавн об'єктів боса
	var teleporter = teleporter_scene.instantiate()
	teleporter.position = boss_pos_pixel
	add_child(teleporter)
	
	var boss = boss_scene.instantiate()
	boss.position = boss_pos_pixel
	boss.died.connect(teleporter.activate)
	add_child(boss)
	
	# 4. СПАВН ГРАВЦЯ (Пошук найдальшої точки)
	var player_start_tile = Vector2i(0, 0)
	var max_dist = 0.0
	
	for i in range(100):
		var test_tile = valid_spawn_points.pick_random()
		var dist = test_tile.distance_to(boss_room_center)
		
		if dist > max_dist:
			max_dist = dist
			player_start_tile = test_tile
	
	player.position = dungeon_generator.floor_layer.map_to_local(player_start_tile)
	
	# 5. СПАВН СУНДУКІВ (Нове!)
	for i in range(5):
		spawn_chest()
	
	# 6. Налаштування гри
	spawn_timer.start()
	MusicManager.play_battle_music()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	# 7. Оновлення UI (Score + HP)
	score = GameManager.current_score
	score_label.text = "Score: " + str(score)
	# Підключаємо сигнал статистики
	player.stats_updated.connect(stats_panel.update_stats)
	
	player.health_changed.connect(health_bar.update_health)
	# Оновлюємо ХП-бар значенням з GameManager, яке ми перенесли з минулого рівня
	health_bar.update_health(GameManager.current_health, GameManager.max_health)

func _on_spawn_timer_timeout():
	if valid_spawn_points.is_empty(): return
	
	# Вибираємо випадкову сцену ворога
	var random_enemy_scene = enemy_scenes.pick_random()
	var enemy_instance = random_enemy_scene.instantiate()
	
	# Вибираємо випадкову плитку підлоги
	var random_tile = valid_spawn_points.pick_random()
	var spawn_pos = dungeon_generator.floor_layer.map_to_local(random_tile)
	
	# Перевірка дистанції (щоб не спавнились на голові)
	if spawn_pos.distance_to($Player.position) < 250:
		return
		
	enemy_instance.global_position = spawn_pos
	enemy_instance.died.connect(_on_enemy_died)
	add_child(enemy_instance)

func _on_enemy_died():
	score += 1
	score_label.text = "Score: " + str(score)
	
	# Оновлюємо глобальний рахунок одразу
	GameManager.current_score = score
	
	# Ачівка: Перше вбивство
	if score == 1:
		GameManager.unlock_achievement("first_blood", "First Blood!")

func game_over():
	var game_over_instance = game_over_scene.instantiate()
	add_child(game_over_instance)
	# Чекаємо наступного кадру, щоб вузол гарантовано був готовий
	await get_tree().process_frame
	# Тепер, коли ми впевнені, що UI готовий, викликаємо функцію
	game_over_instance.show_final_score(score)
	get_tree().paused = true

func spawn_chest():
	if valid_spawn_points.is_empty(): return
	
	var chest = chest_scene.instantiate()
	
	# Вибираємо випадкову точку
	var random_tile = valid_spawn_points.pick_random()
	var spawn_pos = dungeon_generator.floor_layer.map_to_local(random_tile)
	
	# Перевірка: не спавнити поруч з гравцем (щоб не підібрав випадково)
	if spawn_pos.distance_to(player.position) < 100:
		return
		
	chest.position = spawn_pos
	add_child(chest)

# Цю функцію буде викликати наш глобальний InputManager
func toggle_pause():
	# Просто "перевертаємо" стан паузи
	get_tree().paused = not get_tree().paused
	# І показуємо/ховаємо меню
	pause_menu.visible = not pause_menu.visible
