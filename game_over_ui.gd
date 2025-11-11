extends CanvasLayer

@onready var final_score_label: Label = $VBoxContainer/FinalScoreLabel

# Цю функцію буде викликати головна сцена, щоб передати рахунок
func show_final_score(final_score):
	final_score_label.text = "Score: " + str(final_score)

func _on_button_pressed() -> void:
	# Спочатку знімаємо гру з паузи, інакше нова сцена теж буде на паузі
	get_tree().paused = false
	# Перезавантажуємо поточну активну сцену (тобто main.tscn)
	get_tree().reload_current_scene()
