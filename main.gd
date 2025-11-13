extends Node2D

# Сюди ми перетягнемо сцену ворога
@export var enemy_scenes: Array[PackedScene]
# Посилання на наші точки спавну
@onready var spawn_positions = $SpawnPositions.get_children()
# Таймер для спавну
@onready var spawn_timer = $SpawnTimer
# Змінна для зберігання рахунку
var score = 0
@onready var score_label = $CanvasLayer/Label
@onready var pause_menu = $PauseMenu
@export var game_over_scene: PackedScene

func _ready():
	# Запускаємо таймер при старті гри
	spawn_timer.start()

func _on_spawn_timer_timeout():
# 1. Вибираємо випадкову сцену з нашого масиву
	var random_enemy_scene = enemy_scenes.pick_random()
# 2. Створюємо екземпляр саме цієї випадкової сцени
	var enemy_instance = random_enemy_scene.instantiate()
	var random_spawn_point = spawn_positions.pick_random()
	enemy_instance.global_position = random_spawn_point.global_position
	
	# Підключаємось до сигналу "died" цього конкретного ворога
	enemy_instance.died.connect(_on_enemy_died)
	
	add_child(enemy_instance)
	
func _on_enemy_died():
	score += 1 # Збільшуємо рахунок
	score_label.text = "Score: " + str(score) # Оновлюємо текст

func game_over():
	var game_over_instance = game_over_scene.instantiate()
	add_child(game_over_instance)
	# Чекаємо наступного кадру, щоб вузол гарантовано був готовий
	await get_tree().process_frame
	# Тепер, коли ми впевнені, що UI готовий, викликаємо функцію
	game_over_instance.show_final_score(score)
	get_tree().paused = true

# Цю функцію буде викликати наш глобальний InputManager
func toggle_pause():
	# Просто "перевертаємо" стан паузи
	get_tree().paused = not get_tree().paused
	# І показуємо/ховаємо меню
	pause_menu.visible = not pause_menu.visible
