extends Node

# Ця функція викликається один раз, коли цей вузол додається до дерева сцени
func _enter_tree():
	# Встановлюємо режим обробки, щоб він ігнорував паузу
	process_mode = Node.PROCESS_MODE_ALWAYS

# Ця функція вбудована в Godot і викликається ЗАВЖДИ
func _unhandled_input(event):
	# Перевіряємо, чи існує зараз дерево сцени і чи є в ньому вузол "Map"
	if get_tree().root.has_node("Map"):
		# Якщо так, отримуємо посилання на нього
		var main_scene = get_tree().root.get_node("Map")
		
		# Перевіряємо, чи натиснута клавіша Escape
		if event.is_action_pressed("ui_cancel"):
			# Викликаємо спеціальну функцію в нашій головній сцені
			main_scene.toggle_pause()
