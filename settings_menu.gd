extends Control

@onready var fullscreen_check = $VBoxContainer/FullscreenCheck
@onready var vsync_check = $VBoxContainer/VsyncCheck
@onready var volume_slider = $VBoxContainer/VolumeSlider
var is_opened_from_pause = false

func _ready():
	# --- СИНХРОНІЗАЦІЯ UI З РЕАЛЬНИМИ НАЛАШТУВАННЯМИ ---
	
	# Перевіряємо, чи зараз повний екран
	var mode = DisplayServer.window_get_mode()
	fullscreen_check.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Перевіряємо V-Sync
	var vsync = DisplayServer.window_get_vsync_mode()
	vsync_check.button_pressed = (vsync == DisplayServer.VSYNC_ENABLED)
	
	# Перевіряємо гучність (беремо з шини "Master")
	var bus_index = AudioServer.get_bus_index("Master")
	var db = AudioServer.get_bus_volume_db(bus_index)
	# Конвертуємо децибели назад у лінійну шкалу (0.0 - 1.0)
	volume_slider.value = db_to_linear(db)

# --- СИГНАЛИ ---

func _on_fullscreen_check_toggled(button_pressed):
	if button_pressed:
		# Використовуємо звичайний FULLSCREEN (безрамкове вікно), він найнадійніший
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_check_toggled(button_pressed):
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_volume_slider_value_changed(value):
	# Змінюємо гучність шини Master
	var bus_index = AudioServer.get_bus_index("Master")
	# Конвертуємо 0.0-1.0 у децибели
	# Якщо значення 0, ставимо повну тишу (-80dB), щоб уникнути помилок логарифма
	if value <= 0:
		AudioServer.set_bus_volume_db(bus_index, -80)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_back_button_pressed():
	if is_opened_from_pause:
		# Якщо відкрили з паузи - просто знищуємо це вікно налаштувань
		queue_free()
	else:
		# Якщо відкрили з головного меню - міняємо сцену
		get_tree().change_scene_to_file("res://main_menu.tscn")
