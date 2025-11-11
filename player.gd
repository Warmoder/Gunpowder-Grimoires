extends CharacterBody2D

# Швидкість руху гравця. @export робить її видимою в редакторі.
@export var speed = 400.0
# Сюди ми в редакторі перетягнемо нашу сцену кулі
@export var bullet_scene: PackedScene

@onready var shoot_timer = $ShootTimer

func _physics_process(delta):
	# --- Рух ---
	# Отримуємо напрямок з клавіш WASD або стрілок. Godot сам все розуміє.
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	
	# Спеціальна функція CharacterBody2D, яка рухає тіло і обробляє зіткнення зі стінами
	move_and_slide()

	# --- Прицілювання ---
	# Повертаємо гравця в бік курсора миші
	look_at(get_global_mouse_position())
	
	# --- Стрільба (поки що це просто перевірка) ---
	if Input.is_action_just_pressed("fire") and shoot_timer.is_stopped():
		fire()

# Ця функція буде викликатись, коли гравець має померти
func die():
	# Замість перезапуску, повідомляємо головну сцену
	get_tree().root.get_node("Map").game_over()
	queue_free() # Видаляємо гравця

func fire():
	# Перевіряємо, чи ми взагалі вказали сцену кулі
	if not bullet_scene:
		$ShootSound.play() # Програємо звук
		shoot_timer.start() # Запускаємо таймер перезарядки
		return

	# Створюємо екземпляр (копію) сцени кулі
	var bullet_instance = bullet_scene.instantiate()
	
	# Додаємо кулю до головної сцени (щоб вона з'явилась у світі)
	get_tree().root.add_child(bullet_instance)
	
	# Встановлюємо початкову позицію та напрямок кулі
	# transform.x - це напрямок "вперед" для нашого гравця
	bullet_instance.transform = transform
	# Даємо кулі напрямок, куди вона має летіти
	bullet_instance.direction = transform.x


func _on_area_2d_body_entered(body: Node2D) -> void:
	# Перевіряємо, чи тіло, з яким ми зіткнулись, належить до групи "enemies"
	if body.is_in_group("enemies"):
		# Викликаємо нашу власну функцію смерті
		die()
