extends CanvasLayer

# Ця функція викликається кнопкою "Easy"
func _on_easy_button_pressed():
	GameManager.start_new_game(GameManager.Difficulty.EASY)

# Ця функція викликається кнопкою "Hard"
func _on_hard_button_pressed():
	# Звертаємось до нашого глобального GameManager і встановлюємо складність
	GameManager.set_difficulty(GameManager.Difficulty.HARD)
	# Запускаємо ігрову сцену
	get_tree().change_scene_to_file("res://main.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
