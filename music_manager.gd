extends Node

# Сюди ми перетягнемо файли музики в Інспекторі
@export var menu_music: AudioStream
@export var battle_music: AudioStream

@onready var player = $AudioStreamPlayer

# Функція для вмикання музики Меню
func play_menu_music():
	_play_stream(menu_music)

# Функція для вмикання музики Бою
func play_battle_music():
	_play_stream(battle_music)

# Внутрішня функція, яка робить магію
func _play_stream(music_stream):
	# 1. Якщо ця музика ВЖЕ грає - нічого не робимо (хай грає далі)
	if player.stream == music_stream and player.playing:
		return
	
	# 2. Якщо грає щось інше або тиша - ставимо нову музику
	player.stream = music_stream
	player.play()
