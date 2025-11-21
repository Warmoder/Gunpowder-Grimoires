extends Node
enum Difficulty { EASY, HARD }
var current_difficulty = Difficulty.HARD # Складність за замовчуванням
var max_health = 1
# Завантажуємо сцени (Preload - це завантаження в пам'ять одразу)
var health_potion = preload("res://health_potion.tscn")
var damage_up = preload("res://damage_up.tscn")

func set_difficulty(difficulty_level):
	current_difficulty = difficulty_level
	if current_difficulty == Difficulty.EASY:
		max_health = 3
	else:
		max_health = 1

# Функція для отримання випадкового предмета (або нічого)
func get_random_loot():
	var roll = randf() # Випадкове число від 0.0 до 1.0
	
	if roll < 0.05: # 5% шанс
		return damage_up
	elif roll < 0.20: # 15% шанс (від 0.05 до 0.20)
		return health_potion
	
	return null # 80% шанс, що нічого не випаде
