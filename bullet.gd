extends Area2D

# Швидкість кулі в пікселях за секунду
var speed = 1000.0
# Напрямок, в якому летить куля. Його задасть гравець при пострілі.
var direction = Vector2.UP

func _process(delta):
	# Рухаємо кулю в заданому напрямку
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("is_in_group") and body.is_in_group("enemies"):
		body.queue_free()
		# Випускаємо сигнал, щоб повідомити всіх, що ми вбили ворога
	if body.has_method("kill"): # Перевіряємо, чи є у тіла метод "kill"
		body.kill() # Кажемо ворогу "помри!"
	
	queue_free()
