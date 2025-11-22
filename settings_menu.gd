extends Control

@onready var fullscreen_check = $VBoxContainer/FullscreenCheck
@onready var vsync_check = $VBoxContainer/VsyncCheck
@onready var volume_slider = $VBoxContainer/VolumeSlider

func _ready():
	# --- СИНХРОНІЗАЦІЯ UI З РЕАЛЬНИМИ НАЛАШТУВАННЯМИ ---
	
	# Перевіряємо, чи зараз повний екран
	var mode = DisplayServer.window_get_mode()
	fullscreen_check.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Перевіряємо V-Sync
	var vsync = DisplayServer.window_get_vsync_mode()
	vsync_check.button_pressed = (vsync == DisplayServer.VSYNC_ENABLED)
	
	# --- ВИПРАВЛЕНО: Беремо гучність зі збережених даних GameManager ---
	if GameManager.save_data.has("music_volume"):
		volume_slider.value = GameManager.save_data["music_volume"]
	else:
		# Якщо збереження немає, беремо поточну (зазвичай 1.0)
		var bus_index = AudioServer.get_bus_index("Master")
		var db = AudioServer.get_bus_volume_db(bus_index)
		volume_slider.value = db_to_linear(db)

# --- СИГНАЛИ ---

func _on_fullscreen_check_toggled(button_pressed):
	if button_pressed:
		# Цей режим набагато надійніший для ігор
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_check_toggled(button_pressed):
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_volume_slider_value_changed(value):
	# --- ВИПРАВЛЕНО: Викликаємо функцію GameManager ---
	# Ця функція зробить 3 речі:
	# 1. Змінить звук у грі.
	# 2. Оновить змінну.
	# 3. Збереже це у файл savegame.json.
	GameManager.set_volume(value)

func _on_back_button_pressed():
	# Повертаємось в головне меню
	get_tree().change_scene_to_file("res://main_menu.tscn")
