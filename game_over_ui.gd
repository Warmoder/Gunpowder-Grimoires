extends CanvasLayer

@onready var final_score_label = $VBoxContainer/FinalScoreLabel
@onready var high_scores_label = $VBoxContainer2/HighScoresLabel

func show_final_score(final_score):
	final_score_label.text = "Score: " + str(final_score)

	# 1. Зберігаємо наш результат
	GameManager.add_score_to_board(final_score)
	
	# 2. Отримуємо список рекордів через функцію
	var high_scores = GameManager.get_high_scores()
	
	# 3. Показуємо їх
	var text = "\nTop Scores:\n"
	for score in high_scores:
		text += str(score) + "\n"
	
	high_scores_label.text = text

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed():
	# Важливо: спочатку знімаємо гру з паузи
	get_tree().paused = false
	# А потім переходимо в головне меню
	get_tree().change_scene_to_file("res://main_menu.tscn")
