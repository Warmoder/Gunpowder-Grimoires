extends Node2D

# Сюди ми перетягнемо сцену ворога
@export var enemy_scene: PackedScene
# Посилання на наші точки спавну
@onready var spawn_positions = $SpawnPositions.get_children()
# Таймер для спавну
@onready var spawn_timer = $SpawnTimer
# Змінна для зберігання рахунку
var score = 0
@onready var score_label = $CanvasLayer/Label

@export var game_over_scene: PackedScene

func _ready():
	# Запускаємо таймер при старті гри
	spawn_timer.start()

func _on_spawn_timer_timeout():
	var enemy_instance = enemy_scene.instantiate()
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
	get_tree().paused = true # Ставимо гру на паузу
