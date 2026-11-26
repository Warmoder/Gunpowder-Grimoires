extends CanvasLayer

# Ця функція викликається кнопкою "Easy"
func _on_easy_button_pressed():
	GameManager.start_new_game(GameManager.Difficulty.EASY)

# Ця функція викликається кнопкою "Hard"
func _on_hard_button_pressed():
	GameManager.start_new_game(GameManager.Difficulty.HARD)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
