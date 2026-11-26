extends Control

@onready var rich_text_label = $VBoxContainer/RichTextLabel

# Швидкість прокрутки
var scroll_speed = 40.0
# Прапорець
var is_auto_scrolling = true

func _ready():
	# Чекаємо 1 кадр, щоб UI точно встиг прорахувати розміри тексту
	await get_tree().process_frame

func _process(delta):
	if is_auto_scrolling and rich_text_label:
		var scroll_bar = rich_text_label.get_v_scroll_bar()
		
		# Рухаємо вниз
		scroll_bar.value += scroll_speed * delta
		
		# --- НАДІЙНА ПЕРЕВІРКА КІНЦЯ ---
		# scroll_bar.value = скільки прокрутили зверху
		# scroll_bar.page = висота видимого вікна
		# scroll_bar.max_value = повна висота всього тексту
		# -1.0 - це маленький запас похибки для дробних чисел
		
		if scroll_bar.value + scroll_bar.page >= scroll_bar.max_value - 1.0:
			is_auto_scrolling = false
			print("Credits finished scrolling")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_rich_text_label_meta_clicked(meta):
	OS.shell_open(str(meta))

# Зупинка, якщо гравець крутить колесом сам
func _input(event):
	if is_auto_scrolling and event is InputEventMouseButton:
		# Якщо натиснули будь-яку кнопку миші або покрутили колесо
		if event.pressed:
			is_auto_scrolling = false
