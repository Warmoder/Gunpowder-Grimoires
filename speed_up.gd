extends Area2D

@export var duration = 7.0 # Бонус діє 7 секунд

func _on_body_entered(body):
	# Перевіряємо, чи це гравець і чи є у нього потрібна функція
	if body.is_in_group("player") and body.has_method("boost_speed"):
		# Викликаємо функцію прискорення у гравця
		body.boost_speed(duration)
		# Знищуємо бонус після підбору
		queue_free()
