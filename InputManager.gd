extends Node

func _enter_tree():
	# Встановлюємо режим обробки, щоб він ігнорував паузу
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	# Перевіряємо, чи існує зараз дерево сцени і чи є в ньому вузол "Map"
	if get_tree().root.has_node("Map"):
		
		var main_scene = get_tree().root.get_node("Map")
		
		# Перевіряємо, чи натиснута клавіша Escape або кнопка "Назад" на Android
		if event.is_action_pressed("ui_cancel"):
			
			# Кажемо системі, що ми обробили подію (важливо для Android)
			get_tree().root.set_input_as_handled()
			
			# Викликаємо нашу функцію паузи
			main_scene.toggle_pause()
