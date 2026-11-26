extends CanvasLayer

var settings_scene = preload("res://settings_menu.tscn")

# Ця функція буде викликана, коли ми натиснемо "Resume"
func _on_resume_button_pressed():
	# Знімаємо гру з паузи
	get_tree().paused = false
	# І ховаємо саме меню паузи
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var crosshair = get_node_or_null("/root/CrosshairUi")
	if crosshair:
		crosshair.visible = true

# Ця функція буде викликана, коли ми натиснемо "Back to Main Menu"
func _on_main_menu_button_pressed():
	# Важливо: спочатку знімаємо гру з паузи
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var crosshair = get_node_or_null("/root/CrosshairUi")
	if crosshair:
		crosshair.visible = false
	# А потім переходимо в головне меню
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_settings_button_pressed():
	# 1. Створюємо вікно налаштувань
	var settings_instance = settings_scene.instantiate()
	
	# 2. Кажемо йому: "Ти відкрито з паузи!"
	settings_instance.is_opened_from_pause = true
	
	# 3. Додаємо його на екран (додаємо до поточного CanvasLayer)
	add_child(settings_instance)
