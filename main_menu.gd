extends Control

# Ця функція завантажить нашу ігрову сцену
func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

# Ця функція закриє гру
func _on_quit_button_pressed():
	get_tree().quit()
