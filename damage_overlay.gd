extends CanvasLayer

@onready var color_rect = $ColorRect

func flash():
	# Червоний (Damage)
	color_rect.color = Color(1, 0, 0, 0) # Червоний прозорий
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.3, 0.1)
	tween.tween_property(color_rect, "color:a", 0.0, 0.4)

func flash_heal():
	# Зелений (Heal)
	color_rect.color = Color(0, 1, 0, 0) # Зелений прозорий
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.3, 0.1) # Швидко з'являється
	tween.tween_property(color_rect, "color:a", 0.0, 0.6) # Повільно зникає (приємний ефект)
