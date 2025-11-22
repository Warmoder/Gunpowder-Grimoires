extends CanvasLayer

@onready var final_score_label = $VBoxContainer/FinalScoreLabel
@onready var high_scores_label = $VBoxContainer/HighScoresLabel # Новий лейбл

func show_final_score(final_score):
	final_score_label.text = "Score: " + str(final_score)
	
	# 1. Зберігаємо наш результат
	GameManager.add_score(final_score)
	
	# 2. Перевіряємо ачівку "Виживший"
	if final_score >= 10:
		GameManager.unlock_achievement("survivor", "Survivor (10+ Score)")
	
	# 3. Показуємо топ-5
	var text = "\nTop Scores:\n"
	for score in GameManager.save_data["high_scores"]:
		text += str(score) + "\n"
	
	high_scores_label.text = text

func _on_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
