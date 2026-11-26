extends Node

var is_rebinding_key: bool = false

func _enter_tree():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	if is_rebinding_key:
		return
	# --- ПРАЦЮЄМО ТІЛЬКИ НА НЕ-АНДРОЇД ПЛАТФОРМАХ ---
	if OS.get_name() != "Android":
		if event.is_action_pressed("ui_cancel"):
			var main_scene = get_tree().current_scene
			if main_scene and main_scene.has_method("toggle_pause"):
				main_scene.toggle_pause()
			elif get_tree().root.has_node("Map"):
				var map = get_tree().root.get_node("Map")
				if map.has_method("toggle_pause"):
					map.toggle_pause()
		elif InputMap.has_action("toggle_fullscreen") and event.is_action_pressed("toggle_fullscreen"):
			GameManager.settings_data["fullscreen"] = not GameManager.settings_data.get("fullscreen", false)
			GameManager.apply_settings()
			GameManager.save_settings()
		elif InputMap.has_action("toggle_minimap") and event.is_action_pressed("toggle_minimap"):
			GameManager.settings_data["show_minimap"] = not GameManager.settings_data.get("show_minimap", true)
			GameManager.update_minimap_visibility()
			GameManager.save_settings()
