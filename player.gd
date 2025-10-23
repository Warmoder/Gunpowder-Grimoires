extends CharacterBody2D

# Швидкість руху гравця. @export робить її видимою в редакторі.
@export var speed = 400.0

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
	if Input.is_action_just_pressed("fire"):
		fire()

func fire():
	# Ця функція буде викликатись при пострілі.
	# Поки що вона просто виводить повідомлення в консоль внизу.
	print("Bang!")
