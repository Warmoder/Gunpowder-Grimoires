extends CanvasLayer

@onready var color_rect = $ColorRect
var _active_tween: Tween = null

func flash():
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()
	# Червоний (Damage)
	color_rect.color = Color(1, 0, 0, 0) # Червоний прозорий
	_active_tween = create_tween()
	_active_tween.tween_property(color_rect, "color:a", 0.3, 0.1)
	_active_tween.tween_property(color_rect, "color:a", 0.0, 0.4)

func flash_heal():
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()
	# Зелений (Heal)
	color_rect.color = Color(0, 1, 0, 0) # Зелений прозорий
	_active_tween = create_tween()
	_active_tween.tween_property(color_rect, "color:a", 0.3, 0.1) # Швидко з'являється
	_active_tween.tween_property(color_rect, "color:a", 0.0, 0.6) # Повільно зникає (приємний ефект)
