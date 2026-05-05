extends CanvasLayer

# Якщо ти хочеш протестувати кнопки на ПК, постав тут галочку в Інспекторі
@export var debug_show_on_pc: bool = false

func _ready():
	# Перевіряємо платформу
	var os = OS.get_name()
	
	# Якщо це не мобільний телефон і не ввімкнено дебаг-режим — ховаємо весь UI
	if not debug_show_on_pc and os != "Android" and os != "iOS":
		hide()
	else:
		show()
		print("Мобільне керування активовано (OS: ", os, ")")

# Можна додати візуальний фідбек при натисканні (опціонально)
# TouchScreenButton сам надсилає сигнали в Input Map, 
# тому тут більше коду писати не обов'язково.
