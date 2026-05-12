extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var label = $Label

func _ready():
	# Встановлюємо текст і робимо повністю видимим
	label.text = "Level " + str(GameManager.current_level)
	color_rect.modulate.a = 1.0
	label.modulate.a = 1.0
	
func start_fade_out():
	var tween = create_tween()
	
	# Чекаємо 1.5 секунди (щоб гравець прочитав рівень)
	tween.tween_interval(1.5)
	
	# Плавно прибираємо текст і чорний фон
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(color_rect, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	queue_free()
