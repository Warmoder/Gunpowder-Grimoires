extends Node

# Сюди ми перетягнемо файли музики в Інспекторі
@export var menu_music: AudioStream
@export var battle_music: AudioStream
@export var alt_music: AudioStream # ОДИН АЛЬТ-ТРЕК ДЛЯ ВСЬОГО

@onready var player = $AudioStreamPlayer

# Функція для вмикання музики Меню
func play_menu_music():
	var use_alt = GameManager.settings_data.get("alt_music", false)
	if use_alt and alt_music:
		_play_stream(alt_music)
	else:
		_play_stream(menu_music)

# Функція для вмикання музики Бою
func play_battle_music():
	var use_alt = GameManager.settings_data.get("alt_music", false)
	if use_alt and alt_music:
		_play_stream(alt_music)
	else:
		_play_stream(battle_music)

# Викликається з налаштувань для миттєвої зміни
func update_track_if_playing():
	# Дивимось, де ми зараз (в меню чи в грі), щоб увімкнути правильний трек, якщо галочку зняли
	var current_scene_name = get_tree().current_scene.name
	
	if current_scene_name == "MainMenu":
		play_menu_music()
	else:
		play_battle_music()

# Внутрішня функція, яка робить магію
func _play_stream(music_stream):
	if music_stream == null: return
	
	# Якщо ця музика ВЖЕ грає - нічого не робимо
	if player.stream == music_stream and player.playing:
		return
	
	# Якщо грає щось інше - ставимо нову музику
	player.stream = music_stream
	player.play()
