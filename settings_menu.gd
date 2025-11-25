extends Control

@onready var fullscreen_check = $VBoxContainer/FullscreenCheck
@onready var vsync_check = $VBoxContainer/VsyncCheck
@onready var master_slider = $VBoxContainer/MasterSlider
@onready var sfx_slider = $VBoxContainer/SFXSlider
@onready var music_slider = $VBoxContainer/MusicSlider

var is_opened_from_pause = false

func _ready():
	# Завантажуємо налаштування з GameManager і виставляємо UI
	# Fullscreen
	fullscreen_check.button_pressed = GameManager.settings_data.fullscreen
	# V-Sync
	vsync_check.button_pressed = GameManager.settings_data.vsync
	# Гучність
	master_slider.value = GameManager.settings_data.master_volume
	sfx_slider.value = GameManager.settings_data.sfx_volume
	music_slider.value = GameManager.settings_data.music_volume

# --- СИГНАЛИ ---
# (Функції для Fullscreen і V-Sync залишаються без змін)

func _on_fullscreen_check_toggled(button_pressed):
	GameManager.settings_data.fullscreen = button_pressed
	GameManager.apply_settings() # Просимо GameManager застосувати все
	GameManager.save_settings()

func _on_vsync_check_toggled(button_pressed):
	GameManager.settings_data.vsync = button_pressed
	GameManager.apply_settings()
	GameManager.save_settings()

# --- ПОВЗУНКИ ГУЧНОСТІ ---

func _on_master_slider_value_changed(value):
	GameManager.settings_data.master_volume = value
	_update_bus_volume("Master", value)

func _on_sfx_slider_value_changed(value):
	GameManager.settings_data.sfx_volume = value
	_update_bus_volume("SFX", value)

func _on_music_slider_value_changed(value):
	GameManager.settings_data.music_volume = value
	_update_bus_volume("Music", value)
	
# Допоміжна функція для зміни гучності
func _update_bus_volume(bus_name: String, linear_value: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))

func _on_back_button_pressed():
	# Важливо: зберігаємо налаштування перед виходом!
	GameManager.save_settings()
	
	if is_opened_from_pause:
		queue_free()
	else:
		get_tree().change_scene_to_file("res://main_menu.tscn")
