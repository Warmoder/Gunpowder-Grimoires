extends CharacterBody2D

signal died

@export var explosion_scene: PackedScene

# Швидкість ворога. Зробимо його повільнішим за гравця.
var speed = 150.0

# Змінна для зберігання посилання на гравця
var player

func _physics_process(_delta):
	# Шукаємо гравця, тільки якщо ми його ще не знайшли
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	# Якщо гравця немає на сцені, нічого не робимо
	if not player:
		return

	# Розраховуємо напрямок до гравця
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	
	move_and_slide()
	
	# Цю функцію буде викликати куля
func kill():
	emit_signal("died")
	
	# Створюємо вибух
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_parent().add_child(explosion) # Додаємо на сцену
		explosion.global_position = global_position # Встановлюємо позицію
		explosion.emitting = true
	
	queue_free()
