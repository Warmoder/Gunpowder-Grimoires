extends CanvasLayer

# Ця функція буде викликана, коли ми натиснемо "Resume"
func _on_resume_button_pressed():
	# Знімаємо гру з паузи
	get_tree().paused = false
	# І ховаємо саме меню паузи
	hide()

# Ця функція буде викликана, коли ми натиснемо "Back to Main Menu"
func _on_main_menu_button_pressed():
	# Важливо: спочатку знімаємо гру з паузи
	get_tree().paused = false
	# А потім переходимо в головне меню
	get_tree().change_scene_to_file("res://main_menu.tscn")
