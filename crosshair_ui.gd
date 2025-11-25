extends CanvasLayer

@onready var crosshair = $Crosshair

func _ready():
	# Підключаємось до сигналу зміни сцени
	get_tree().scene_changed.connect(on_scene_changed)
	
	# Викликаємо функцію одразу на старті гри, щоб перевірити першу сцену
	on_scene_changed()

func _process(_delta):
	# Рухаємо приціл, тільки якщо він видимий
	if visible:
		crosshair.position = get_viewport().get_mouse_position()

func on_scene_changed():
	# Отримуємо назву поточної активної сцени
	var current_scene_name = get_tree().current_scene.name
	
	# Перевіряємо, чи це наша ігрова сцена
	if current_scene_name == "Map":
		# Якщо так - показуємо приціл і ховаємо системний курсор
		visible = true
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		# Інакше (в меню, налаштуваннях і т.д.) - ховаємо приціл і показуємо системний курсор
		visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Коли гра закривається, повертаємо системний курсор
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
