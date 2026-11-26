extends Control

# Посилання на лейбли (щоб міняти їм колір)
@onready var ach_1 = $VBoxContainer/Ach1
@onready var ach_2 = $VBoxContainer/Ach2
@onready var ach_3 = $VBoxContainer/Ach3

func _ready():
	update_view()

func update_view():
	# Отримуємо дані через нашу нову, безпечну функцію
	var data = GameManager.get_achievements_data()
	
	# Оновлюємо вигляд кожного лейбла
	# Якщо true (відкрито) - зелений колір, якщо false - сірий
	
	# 1. First Blood
	if data["first_blood"]:
		ach_1.modulate = Color.GREEN
		ach_1.text = "First Blood [UNLOCKED]"
	else:
		ach_1.modulate = Color.GRAY
		ach_1.text = "First Blood [LOCKED]"

	# 2. Survivor
	if data["survivor"]:
		ach_2.modulate = Color.GREEN
		ach_2.text = "Survivor (10+ Score) [UNLOCKED]"
	else:
		ach_2.modulate = Color.GRAY
		ach_2.text = "Survivor (10+ Score) [LOCKED]"

	# 3. Boss Killer
	if data["boss_killer"]:
		ach_3.modulate = Color.GREEN
		ach_3.text = "Boss Killer [UNLOCKED]"
	else:
		ach_3.modulate = Color.GRAY
		ach_3.text = "Boss Killer [LOCKED]"

func _on_reset_button_pressed():
	# Викликаємо скидання
	GameManager.reset_progress()
	# Оновлюємо вигляд (все стане сірим)
	update_view()

func _on_back_button_pressed():
	# Повертаємось в головне меню
	get_tree().change_scene_to_file("res://main_menu.tscn")
