extends Control

@onready var fullscreen_check = $VBoxContainer/FullscreenCheck
@onready var vsync_check = $VBoxContainer/VsyncCheck
@onready var master_slider = $VBoxContainer/MasterSlider
@onready var sfx_slider = $VBoxContainer/SFXSlider
@onready var music_slider = $VBoxContainer/MusicSlider

# --- НОВІ ВУЗЛИ ДЛЯ РОЗДІЛЬНОЇ ЗДАТНОСТІ ---
@onready var prev_res_button = $VBoxContainer/HBoxContainer/PrevResButton
@onready var next_res_button = $VBoxContainer/HBoxContainer/NextResButton
@onready var res_label = $VBoxContainer/HBoxContainer/ResLabel

var is_opened_from_pause = false
var current_res_index = 0

var resolutions = [
	DisplayServer.screen_get_size(), # Нативна (0)
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(960, 540)
]

func _ready():
	# Підключаємо кнопки стрілочок
	if prev_res_button and next_res_button:
		prev_res_button.pressed.connect(_on_prev_res_pressed)
		next_res_button.pressed.connect(_on_next_res_pressed)

	# Завантажуємо збережений індекс роздільної здатності
	if GameManager.settings_data.has("resolution_index"):
		current_res_index = GameManager.settings_data["resolution_index"]
	
	update_res_label()

	# Завантажуємо інші налаштування
	fullscreen_check.button_pressed = GameManager.settings_data.fullscreen
	vsync_check.button_pressed = GameManager.settings_data.vsync
	master_slider.value = GameManager.settings_data.master_volume
	sfx_slider.value = GameManager.settings_data.sfx_volume
	music_slider.value = GameManager.settings_data.music_volume

# --- ЛОГІКА РОЗДІЛЬНОЇ ЗДАТНОСТІ ---

func _on_prev_res_pressed():
	current_res_index -= 1
	if current_res_index < 0:
		current_res_index = resolutions.size() - 1 # Перехід в кінець списку
	apply_resolution()

func _on_next_res_pressed():
	current_res_index += 1
	if current_res_index >= resolutions.size():
		current_res_index = 0 # Перехід на початок
	apply_resolution()

func apply_resolution():
	GameManager.settings_data["resolution_index"] = current_res_index
	update_res_label()
	
	if not fullscreen_check.button_pressed:
		var target_size = resolutions[current_res_index]
		DisplayServer.window_set_size(target_size)
		
		# Центруємо вікно
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size / 2) - (target_size / 2)
		DisplayServer.window_set_position(window_pos)

func update_res_label():
	var res = resolutions[current_res_index]
	var text = str(res.x) + " x " + str(res.y)
	
	if current_res_index == 0:
		text += " (Native)"
	elif res.x * 9 == res.y * 16:
		text += " (16:9)"
	elif res.x * 3 == res.y * 4:
		text += " (4:3)"
		
	res_label.text = text

# --- ІНШІ НАЛАШТУВАННЯ ---

func _on_fullscreen_check_toggled(button_pressed):
	GameManager.settings_data.fullscreen = button_pressed
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		apply_resolution() # Повертаємо вибраний розмір вікна
	
	GameManager.apply_settings()
	GameManager.save_settings()

func _on_vsync_check_toggled(button_pressed):
	GameManager.settings_data.vsync = button_pressed
	GameManager.apply_settings()
	GameManager.save_settings()

func _on_master_slider_value_changed(value):
	GameManager.settings_data.master_volume = value
	_update_bus_volume("Master", value)

func _on_sfx_slider_value_changed(value):
	GameManager.settings_data.sfx_volume = value
	_update_bus_volume("SFX", value)

func _on_music_slider_value_changed(value):
	GameManager.settings_data.music_volume = value
	_update_bus_volume("Music", value)
	
func _update_bus_volume(bus_name: String, linear_value: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))

func _on_back_button_pressed():
	GameManager.save_settings()
	if is_opened_from_pause:
		queue_free()
	else:
		get_tree().change_scene_to_file("res://main_menu.tscn")
