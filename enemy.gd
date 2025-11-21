extends CharacterBody2D

@export var health = 3
@export var speed = 150.0
@export var explosion_scene: PackedScene

# Змінна для зберігання гравця
var player
# Змінна для "пам'яті" ворога
var last_known_position: Vector2

@onready var ray_cast = $RayCast

signal died

func _ready():
	# На старті "остання позиція" - це місце, де стоїть сам ворог (щоб він нікуди не біг)
	last_known_position = global_position

func _physics_process(_delta):
	# 1. Шукаємо гравця (якщо ще не знайшли)
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	if not player:
		return

	# 2. Націлюємо лазер
	ray_cast.target_position = to_local(player.global_position)
	ray_cast.force_raycast_update()
	
	var can_see_player = false
	
	# 3. Перевіряємо зір
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider.is_in_group("player"):
			can_see_player = true
	
	# 4. Логіка руху (Штучний Інтелект)
	if can_see_player:
		# --- БАЧУ ГРАВЦЯ ---
		# Запам'ятовуємо, де він зараз
		last_known_position = player.global_position
		# І біжимо прямо на нього
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
	else:
		# --- НЕ БАЧУ ГРАВЦЯ ---
		# Перевіряємо, чи ми вже дійшли до того місця, де бачили його востаннє?
		# distance_to перевіряє відстань. Якщо вона менше 10 пікселів - ми прийшли.
		if global_position.distance_to(last_known_position) > 10:
			# Ще не прийшли -> біжимо до точки пам'яті
			var direction = global_position.direction_to(last_known_position)
			velocity = direction * speed
		else:
			# Прийшли, нікого немає -> Зупиняємось
			velocity = Vector2.ZERO

	move_and_slide()

# Цю функцію викликає куля
func take_damage(amount):
	health -= amount # Віднімаємо здоров'я

	# Перевіряємо, чи здоров'я закінчилось
	if health <= 0:
		emit_signal("died")
		
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			get_tree().root.add_child(explosion)
			explosion.global_position = global_position
			explosion.emitting = true
		
		drop_loot()
		queue_free()

func _on_attack_area_body_entered(body: Node2D) -> void:
	# Перевіряємо, чи це точно гравець і чи є у нього функція die()
	if body.has_method("die"):
		body.die() # Кажемо гравцю "отримай шкоду"
		queue_free() # Ворог-камікадзе знищує себе після атаки

func drop_loot():
	# Питаємо у GameManager, чи випало щось
	var loot_scene = GameManager.get_random_loot()
	
	if loot_scene:
		var loot = loot_scene.instantiate()
		# Додаємо в корінь сцени (щоб лут не зник разом з ворогом)
		get_tree().root.call_deferred("add_child", loot)
		loot.global_position = global_position
