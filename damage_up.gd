extends Area2D

@export var duration = 5.0 # Бонус діє 5 секунд

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("boost_damage"):
			body.boost_damage(duration)
			queue_free()
