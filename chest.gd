extends Area2D

@onready var open_sound: AudioStreamPlayer2D = $OpenSound
@export var open_sprite_texture: Texture2D

var is_opened = false

func _on_body_entered(body):
	# Якщо вже відкритий - ігноруємо
	if is_opened: return
	
	# Перевіряємо, чи це гравець
	if body.is_in_group("player"):
		open_chest()
		open_sound.play()

func open_chest():
	is_opened = true
	
	# 1. Змінюємо спрайт
	if open_sprite_texture:
		$Sprite2D.texture = open_sprite_texture
	
	# 2. Спавнимо лут (код луту залишається тим самим...)
	var loot_scene = GameManager.get_random_loot()
	while loot_scene == null:
		loot_scene = GameManager.get_random_loot()
		
	var loot = loot_scene.instantiate()
	get_tree().root.call_deferred("add_child", loot)
	loot.global_position = global_position + Vector2(0, 20)
	
	# 3. Чекаємо 15 секунд і зникаємо
	var timer = get_tree().create_timer(15.0)
	await timer.timeout
	
	# Плавно зникаємо (анімація прозорості за 1 секунду)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	queue_free()
