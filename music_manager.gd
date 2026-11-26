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
	# Дивимось, де ми зараз (в бою "Map" чи в меню), щоб увімкнути правильний трек
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	if current_scene.name == "Map":
		play_battle_music()
	else:
		play_menu_music()

# Внутрішня функція, яка робить магію
func _play_stream(music_stream):
	if music_stream == null: return
	
	# Якщо ця музика ВЖЕ грає - нічого не робимо
	if player.stream == music_stream and player.playing:
		return
	
	# Якщо грає щось інше - ставимо нову музику
	player.stream = music_stream
	player.play()
