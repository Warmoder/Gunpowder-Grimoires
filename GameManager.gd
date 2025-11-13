extends Node
enum Difficulty { EASY, HARD }
var current_difficulty = Difficulty.HARD # Складність за замовчуванням
var max_health = 1

func set_difficulty(difficulty_level):
	current_difficulty = difficulty_level
	if current_difficulty == Difficulty.EASY:
		max_health = 3
	else:
		max_health = 1
