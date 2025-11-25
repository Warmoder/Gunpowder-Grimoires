extends CharacterBody2D

@export var health = 15
@export var speed = 70.0
@export var stop_distance = 200.0

@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@export var muzzle_flash_scene: PackedScene

@onready var shoot_sound = $ShootSound
@onready var ray_cast = $RayCast
@onready var shoot_timer = $ShootTimer
@onready var base_max_health = health
@onready var base_speed = speed

# Змінна для зберігання посилання на гравця
var player
# Змінна для пам'яті
var last_known_position: Vector2

signal died

func _ready():
		# Отримуємо множник (наприклад, 1.2 на 3-му рівні)
	var multiplier = GameManager.get_difficulty_multiplier()
	
	# Посилюємо ворога
	health = base_max_health * multiplier
	speed = base_speed * multiplier # Або трохи менше, наприклад * (1 + (multiplier-1)*0.5), щоб вони не стали Флешами
	shoot_timer.timeout.connect(fire)
	last_known_position = global_position

func _physics_process(_delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# --- ЗІР ---
	ray_cast.target_position = to_local(player.global_position)
	ray_cast.force_raycast_update()
	
	var can_see_player = false
	
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider.is_in_group("player"):
			can_see_player = true
	
	# --- ПОВЕДІНКА ---
	if can_see_player:
		last_known_position = player.global_position
		look_at(player.global_position)
		
		if shoot_timer.is_stopped():
			shoot_timer.start()
			
		var dist = global_position.distance_to(player.global_position)
		if dist > stop_distance:
			velocity = global_position.direction_to(player.global_position) * speed
		else:
			velocity = Vector2.ZERO
	else:
		shoot_timer.stop()
		if global_position.distance_to(last_known_position) > 10:
			look_at(last_known_position)
			velocity = global_position.direction_to(last_known_position) * speed
		else:
			velocity = Vector2.ZERO

	move_and_slide()

func fire():
	if not bullet_scene: return
	
	var bullet_instance = bullet_scene.instantiate()
	get_tree().root.add_child(bullet_instance)
	
	# Правильний виліт кулі (з дула + поворот)
	bullet_instance.global_position = $Sprite2D/Muzzle.global_position
	bullet_instance.rotation = global_rotation
	bullet_instance.direction = transform.x

	# Спавн спалаху
	if muzzle_flash_scene:
		var flash = muzzle_flash_scene.instantiate()
		# Додаємо як дочірній до Muzzle, щоб він рухався разом зі зброєю
		$Sprite2D/Muzzle.add_child(flash)

	shoot_sound.play()
	shoot_timer.start()

func take_damage(amount):
	health -= amount
	if health <= 0:
		# Логіка смерті боса
		drop_loot()
		GameManager.unlock_achievement("boss_killer", "Boss Killer!")
		emit_signal("died")
		
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			get_tree().root.add_child(explosion)
			explosion.global_position = global_position
			explosion.emitting = true
		
		queue_free()

# --- ГОЛОВНА ЗМІНА ДЛЯ БОСА ---
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		# Вбиваємо гравця МИТТЄВО (обнуляємо здоров'я)
		# Щит (якщо є) врятує від цього один раз, але друге торкання - смерть.
		body.current_health = 0
		body.die()
		
		# МИ НЕ ПИШЕМО queue_free()!!!
		# Бос занадто крутий, щоб помирати від дотику до гравця.

func drop_loot():
	var loot_scene = GameManager.get_random_loot()
	if loot_scene:
		var loot = loot_scene.instantiate()
		get_tree().root.call_deferred("add_child", loot)
		loot.global_position = global_position
