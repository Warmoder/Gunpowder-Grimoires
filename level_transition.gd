extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var label = $Label

func _ready():
	# 1. Встановлюємо текст
	label.text = "Level " + str(GameManager.current_level)
	
	# 2. Робимо все видимим
	color_rect.modulate.a = 1.0
	label.modulate.a = 1.0
	
	# 3. Анімація зникнення (Fade Out)
	var tween = create_tween()
	
	# Чекаємо 1.5 секунди (щоб гравець прочитав рівень)
	tween.tween_interval(1.5)
	
	# Плавно прибираємо текст і чорний фон
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(color_rect, "modulate:a", 0.0, 0.5)
	
	# Після анімації видаляємо сцену переходу, щоб не заважала
	await tween.finished
	queue_free()
