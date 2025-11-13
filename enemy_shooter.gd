extends CharacterBody2D

@export var health = 2 # Зробимо його трохи слабшим

@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene

@onready var shoot_timer = $ShootTimer

# Змінна для зберігання посилання на гравця
var player

signal died

func _ready():
	# Підключаємо сигнал таймера до функції пострілу
	shoot_timer.timeout.connect(fire)

func _process(_delta):
	# Шукаємо гравця
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	if not player:
		return

	# Завжди дивимось на гравця
	look_at(player.global_position)

func fire():
	if not bullet_scene or not is_instance_valid(player):
		return

	var bullet_instance = bullet_scene.instantiate()
	get_tree().root.add_child(bullet_instance)
	
	bullet_instance.transform = transform
	bullet_instance.direction = transform.x

func take_damage(amount):
	health -= amount
	if health <= 0:
		emit_signal("died")
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			get_tree().root.add_child(explosion)
			explosion.global_position = global_position
			explosion.emitting = true
		queue_free()


func _on_attack_area_body_entered(body: Node2D) -> void:
	# Перевіряємо, чи це точно гравець і чи є у нього функція die()
	if body.has_method("die"):
		body.die() # Кажемо гравцю "отримай шкоду"
		queue_free() # Ворог-камікадзе знищує себе після атаки
