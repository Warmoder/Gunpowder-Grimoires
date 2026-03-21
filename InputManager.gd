extends Node

func _enter_tree():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	# --- ПРАЦЮЄМО ТІЛЬКИ НА НЕ-АНДРОЇД ПЛАТФОРМАХ ---
	if OS.get_name() != "Android":
		
		if get_tree().root.has_node("Map"):
			var main_scene = get_tree().root.get_node("Map")
			
			if event.is_action_pressed("ui_cancel"):
				main_scene.toggle_pause()
