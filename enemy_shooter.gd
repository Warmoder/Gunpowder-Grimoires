extends CharacterBody2D

@export var health = 2
@export var speed = 80.0 # Швидкість руху (повільніше за мілішника)
@export var stop_distance = 250.0 # Дистанція, на якій він зупиниться
@onready var shoot_sound = $ShootSound
@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene

@onready var ray_cast = $RayCast
@onready var shoot_timer = $ShootTimer

# Змінна для зберігання посилання на гравця
var player
# Змінна для пам'яті (остання позиція, де бачили гравця)
var last_known_position: Vector2

signal died

func _ready():
	# Підключаємо сигнал таймера до функції пострілу
	shoot_timer.timeout.connect(fire)
	# На старті запам'ятовуємо своє місце, щоб нікуди не бігти одразу
	last_known_position = global_position

func _physics_process(_delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# --- 1. ЗІР (RayCast) ---
	ray_cast.target_position = to_local(player.global_position)
	ray_cast.force_raycast_update()
	
	var can_see_player = false
	
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider.is_in_group("player"):
			can_see_player = true
	
	# --- 2. ПОВЕДІНКА (РУХ + СТРІЛЬБА) ---
	
	if can_see_player:
		# --- БАЧУ ГРАВЦЯ ---
		last_known_position = player.global_position # Оновлюємо пам'ять
		look_at(player.global_position) # Дивимось на гравця
		
		# Стрільба: якщо таймер стоїть - запускаємо
		if shoot_timer.is_stopped():
			shoot_timer.start()
			
		# Рух: перевіряємо дистанцію
		var dist_to_player = global_position.distance_to(player.global_position)
		
		if dist_to_player > stop_distance:
			# Якщо ми далеко - підходимо ближче
			var direction = global_position.direction_to(player.global_position)
			velocity = direction * speed
		else:
			# Якщо дистанція хороша - стоїмо
			velocity = Vector2.ZERO
			
	else:
		# --- НЕ БАЧУ ГРАВЦЯ ---
		shoot_timer.stop() # Перестаємо стріляти
		
		# Пам'ять: йдемо перевірити останню відому позицію
		if global_position.distance_to(last_known_position) > 10:
			look_at(last_known_position)
			var direction = global_position.direction_to(last_known_position)
			velocity = direction * speed
		else:
			# Прийшли на місце, нікого немає - стоїмо
			velocity = Vector2.ZERO

	move_and_slide()

func fire():
	if not bullet_scene:
		return
	
	# 1. Створюємо екземпляр кулі
	var bullet_instance = bullet_scene.instantiate()
	
	# 2. Додаємо на сцену
	get_tree().root.add_child(bullet_instance)
	
	# 3. Встановлюємо позицію
	bullet_instance.global_position = $Sprite2D/Muzzle.global_position
	
	# 4. Встановлюємо кут повороту (щоб куля дивилась куди треба)
	bullet_instance.rotation = global_rotation
	
	# 5. НАЙВАЖЛИВІШЕ: Встановлюємо напрямок руху
	# `transform.x` - це вектор, який завжди вказує "вперед" для поточного об'єкта
	# Ми передаємо цей напрямок у змінну `direction` в скрипті кулі
	bullet_instance.direction = transform.x
	
	# 6. Звук і таймер
	shoot_sound.play()
	shoot_timer.start()

func take_damage(amount):
	health -= amount
	if health <= 0:
		# Спочатку дропаємо лут
		drop_loot()
		
		emit_signal("died")
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			get_tree().root.add_child(explosion)
			explosion.global_position = global_position
			explosion.emitting = true # Не забудь про цей фікс для частинок!
		
		queue_free()

# Функція для удару при дотику (твоя стара логіка)
func _on_attack_area_body_entered(body: Node2D) -> void:
	# Перевіряємо, чи це точно гравець і чи є у нього функція die()
	if body.has_method("die"):
		body.die() # Кажемо гравцю "отримай шкоду"
		queue_free() # Стрілець теж зникає, якщо торкнувся гравця

func drop_loot():
	# Питаємо у GameManager, чи випало щось
	var loot_scene = GameManager.get_random_loot()
	
	if loot_scene:
		var loot = loot_scene.instantiate()
		# Додаємо в корінь сцени
		get_tree().root.call_deferred("add_child", loot)
		loot.global_position = global_position
