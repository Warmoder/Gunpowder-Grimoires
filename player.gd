extends CharacterBody2D

# --- ЗМІННІ ---

# Експортовані змінні (налаштовуються в редакторі)
@export var speed = 400.0
@export var bullet_scene: PackedScene

# Посилання на дочірні вузли (ініціалізуються при старті)
@onready var shoot_timer = $ShootTimer
@onready var shoot_sound = $ShootSound # Переконайся, що вузол називається ShootSound
@onready var hitbox = $Hitbox # Додамо для ясності

# Ігрові змінні
var current_health: int
var base_damage = 1
var damage_multiplier = 1

# --- ВБУДОВАНІ ФУНКЦІЇ GODOT ---

func _ready():
	# Встановлюємо здоров'я на старті гри, беручи значення з GameManager
	current_health = GameManager.max_health
	print("Player spawned with health: ", current_health) # Для перевірки

func _process(_delta):
# Отримуємо напрямок від гравця до миші
	var direction_to_mouse = get_global_mouse_position() - global_position
# Встановлюємо кут обертання гравця на основі цього напрямку
	rotation = direction_to_mouse.angle()

func _physics_process(_delta):
	# --- Рух ---
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	
	# --- Стрільба ---
	# Стріляємо, якщо натиснута кнопка "fire" і таймер перезарядки зупинений
	if Input.is_action_just_pressed("fire") and shoot_timer.is_stopped():
		fire()


# --- ВЛАСНІ ФУНКЦІЇ ---

func fire():
	# Перевірка, чи підключена сцена кулі
	if not bullet_scene:
		return
	# Створюємо екземпляр кулі
	var bullet_instance = bullet_scene.instantiate()
	# Передаємо кулі нашу поточну шкоду
	if "damage" in bullet_instance:
		bullet_instance.damage = base_damage * damage_multiplier
	# Додаємо кулю на сцену
	get_tree().root.add_child(bullet_instance)
	# Встановлюємо її позицію та напрямок
	bullet_instance.transform = transform
	bullet_instance.direction = transform.x
	# Програємо звук і запускаємо таймер перезарядки
	shoot_sound.play()
	shoot_timer.start()

# Ця функція викликається ворожою кулею або при зіткненні з ворогом
func die():
	current_health -= 1
	print("Player hit! Health remaining: ", current_health) # Для перевірки
	
	# Перевіряємо, чи здоров'я закінчилось
	if current_health <= 0:
		get_tree().root.get_node("Map").game_over()
		hide() # Ховаємо гравця

func heal(amount):
	# Додаємо здоров'я
	current_health += amount
	
	# Не дозволяємо здоров'ю перевищити максимум
	if current_health > GameManager.max_health:
		current_health = GameManager.max_health
		
	print("Player healed! HP: ", current_health)

func boost_damage(duration):
	damage_multiplier = 2 # Подвійна шкода
	print("Double Damage Activated!")
	
	# Створюємо тимчасовий таймер, щоб вимкнути бонус
	var timer = get_tree().create_timer(duration)
	await timer.timeout # Чекаємо, поки час вийде
	
	damage_multiplier = 1 # Повертаємо як було
	print("Double Damage Ended.")

# --- ОБРОБКА СИГНАЛІВ ---

# Ця функція викликається сигналом "body_entered" від нашого Hitbox
func _on_hitbox_body_entered(body):
	# Перевіряємо, чи зіткнулись ми з ворогом
	if body.is_in_group("enemies"):
		die() # Отримуємо шкоду при прямому зіткненні з ворогом
