extends Area2D

@export var heal_amount = 1

func _on_body_entered(body):
	# Перевіряємо, чи це гравець
	if body.is_in_group("player"):
		# Перевіряємо, чи є у гравця функція лікування
		if body.has_method("heal"):
			body.heal(heal_amount)
			queue_free() # Бонус зникає
