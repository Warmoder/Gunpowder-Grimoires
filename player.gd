extends CharacterBody2D

# --- ЗМІННІ ---

# Експортовані змінні (налаштовуються в редакторі)
@export var speed = 400.0
@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@export var pixels_per_step = 120.0
@export var muzzle_flash_scene: PackedScene

# Посилання на дочірні вузли (ініціалізуються при старті)
@onready var shoot_timer = $ShootTimer
@onready var shoot_sound = $ShootSound
@onready var hitbox = $Hitbox
@onready var shield_sprite = $ShieldSprite
@onready var footstep_sound = $FootstepSound
@onready var step_timer = $StepTimer
@onready var sprite = $Sprite2D # Посилання на спрайт для блимання
@onready var move_stick = get_tree().root.get_node("Map/TouchControls/MoveStick")
@onready var shoot_stick = get_tree().root.get_node("Map/TouchControls/ShootStick")

# Ігрові змінні
var current_health: int
var base_damage = 1
var has_shield = false
var base_speed: float
var speed_boost_count = 0
var damage_boost_count = 0
var is_invincible = false
# Час, що залишився для візуалізації
var speed_time_left: float = 0.0
var damage_time_left: float = 0.0

signal health_changed(current_health, max_health)
signal player_healed
signal stats_updated(damage_mult, damage_time, current_speed, speed_time)
signal player_damaged

# --- ВБУДОВАНІ ФУНКЦІЇ GODOT ---

func _ready():
	# Встановлюємо здоров'я на старті гри, беручи БАЗОВЕ значення
	current_health = GameManager.base_health
	health_changed.emit(current_health, GameManager.max_health) # Повідомляємо UI про максимум
	base_speed = speed

func _process(delta):
	# --- 1. ЛОГІКА ПОВОРОТУ ---
	if OS.get_name() == "Android":
		# На Android повертаємось за правим джойстиком
		if shoot_stick.is_pressed:
			rotation = shoot_stick.output.angle()
	else:
		# На ПК повертаємось за мишкою
		var direction_to_mouse = get_global_mouse_position() - global_position
		rotation = direction_to_mouse.angle()

	# --- 2. ОНОВЛЕННЯ ТАЙМЕРІВ БОНУСІВ (без змін) ---
	if speed_boost_count > 0:
		speed_time_left -= delta
	else:
		speed_time_left = 0
		
	if damage_boost_count > 0:
		damage_time_left -= delta
	else:
		damage_time_left = 0
		
	# --- 3. ВІДПРАВКА ДАНИХ В UI (без змін) ---
	var current_mult = 1.0 + damage_boost_count
	stats_updated.emit(current_mult, damage_time_left, speed, speed_time_left)

func _physics_process(_delta):
	# --- 1. ОТРИМАННЯ НАПРЯМКУ РУХУ ---
	var direction = Vector2.ZERO
	
	if OS.get_name() == "Android":
		# На Android беремо напрямок з лівого джойстика
		direction = move_stick.output
	else:
		# На ПК беремо з клавіатури
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# --- 2. РУХ (без змін) ---
	velocity = direction * speed
	move_and_slide()
	
	# --- 3. ЗВУК КРОКІВ (без змін) ---
	if velocity.length() > 0:
		if step_timer.is_stopped():
			footstep_sound.pitch_scale = randf_range(0.9, 1.1)
			footstep_sound.play()
			var step_time = pixels_per_step / velocity.length()
			step_timer.start(step_time)
	else:
		step_timer.stop()
	
	# --- 4. ЛОГІКА СТРІЛЬБИ ---
	var is_shooting = false
	
	if OS.get_name() == "Android":
		if shoot_stick.output.length() > 0:
			is_shooting = true
	else:
		is_shooting = Input.is_action_pressed("fire")
	
# Стріляємо, якщо є команда і таймер готовий
	if is_shooting and shoot_timer.is_stopped():
		fire()

# --- ВЛАСНІ ФУНКЦІЇ ---

func fire():
	if not bullet_scene: return
	
	var bullet_instance = bullet_scene.instantiate()
	
	# --- НОВИЙ РОЗРАХУНОК ШКОДИ (STACKING) ---
	var current_damage_multiplier = 1.0
	
	current_damage_multiplier += damage_boost_count
	
	if "damage" in bullet_instance:
		bullet_instance.damage = base_damage * current_damage_multiplier
	# ------------------------------------------

	# 3. Додаємо на сцену
	get_tree().root.add_child(bullet_instance)
 
	# 4. Встановлюємо позицію
	bullet_instance.global_position = $Sprite2D/Muzzle.global_position
	# 5. Встановлюємо кут повороту
	bullet_instance.rotation = global_rotation
	# 6. Встановлюємо напрямок руху
	bullet_instance.direction = transform.x

	# Спавн спалаху
	if muzzle_flash_scene:
		var flash = muzzle_flash_scene.instantiate()
		# Додаємо як дочірній до Muzzle, щоб він рухався разом зі зброєю
		$Sprite2D/Muzzle.add_child(flash)

	# 7. Звук і таймер
	shoot_sound.play()
	shoot_timer.start()

# Функція повертає true, якщо шкода була отримана (або щит прийняв удар).
# Повертає false, якщо гравець в i-frame і проігнорував удар.
func die() -> bool:
	# 1. ПЕРЕВІРКА НЕВРАЗЛИВОСТІ
	if is_invincible:
		return false # Ігноруємо удар, ворог не повинен зникати
		
	# 2. ПЕРЕВІРКА ЩИТА
	if has_shield:
		has_shield = false
		shield_sprite.hide()
		print("Shield broke!")
		
		# Даємо коротку невразливість після поломки щита
		start_invincibility(1.0)
		
		# Повертаємо true, щоб ворог-камікадзе зник (він розбився об щит)
		return true
	
	# 3. ОТРИМАННЯ ШКОДИ
	current_health -= 1
	GameManager.current_health = current_health
	
	# Оновлюємо UI та викликаємо ефекти
	health_changed.emit(current_health, GameManager.max_health)
	player_damaged.emit()
	
	print("Player hit! Health: ", current_health)
	
	# 4. ПЕРЕВІРКА СМЕРТІ
	if current_health <= 0:
		# Створюємо вибух
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			get_tree().root.add_child(explosion)
			explosion.global_position = global_position
			explosion.emitting = true
		
		# Кінець гри
		get_tree().root.get_node("Map").game_over()
		hide()
	else:
		# 5. ЯКЩО ВИЖИЛИ - ВМИКАЄМО I-FRAMES
		start_invincibility(2.0) # 2 секунди невразливості
		
	return true # Шкода пройшла успішно

func heal(amount):
	current_health += amount
	GameManager.current_health = current_health
	
	# Не дозволяємо здоров'ю перевищити АБСОЛЮТНИЙ максимум
	if current_health > GameManager.max_health:
		current_health = GameManager.max_health
		
	print("Player healed! HP: ", current_health)
	health_changed.emit(current_health, GameManager.max_health)
	
	player_healed.emit()

func boost_speed(duration):
	speed_boost_count += 1
	speed_time_left = duration # Оновлюємо таймер на максимум
	update_speed()
	
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	
	speed_boost_count -= 1
	update_speed()

func boost_damage(duration):
	damage_boost_count += 1
	damage_time_left = duration # Оновлюємо таймер
	
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	
	damage_boost_count -= 1

func start_invincibility(duration):
	is_invincible = true
	
	# --- АНІМАЦІЯ БЛИМАННЯ ---
	var tween = create_tween()
	# Блимаємо 5 разів
	for i in range(8):
		tween.tween_property(sprite, "modulate:a", 0.5, 0.1) # Прозорий
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1) # Нормальний
		
	# --- ЧЕКАЄМО І ВИМИКАЄМО ---
	# Створюємо таймер на тривалість ефекту
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	
	is_invincible = false
	sprite.modulate.a = 1.0 # Переконуємось, що спрайт видимий
	print("Invincibility ended")

func update_speed():
	# Якщо є хоча б один активний бонус швидкості
	if speed_boost_count > 0:
		speed = base_speed * 1.5 # Швидкість збільшена
	else:
		speed = base_speed # Швидкість звичайна
	
	print("Speed updated. Current speed: ", speed)

func activate_shield():
	has_shield = true
	shield_sprite.show() # Показуємо спрайт щита
	print("Shield Activated!")

# --- ОБРОБКА СИГНАЛІВ ---

# Ця функція викликається сигналом "body_entered" від нашого Hitbox
func _on_hitbox_body_entered(body):
	# Перевіряємо, чи зіткнулись ми з ворогом
	if body.is_in_group("enemies"):
		die() # Отримуємо шкоду при прямому зіткненні з ворогом
