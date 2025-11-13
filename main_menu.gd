extends Control

# Ця функція завантажить нашу ігрову сцену
func _on_start_button_pressed():
	# Тепер ми переходимо на екран вибору складності
	get_tree().change_scene_to_file("res://difficulty_select.tscn")

# Ця функція закриє гру
func _on_quit_button_pressed():
	get_tree().quit()
