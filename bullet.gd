extends Area2D

# Швидкість кулі в пікселях за секунду
var speed = 1000.0
# Напрямок, в якому летить куля. Його задасть гравець при пострілі.
var direction = Vector2.UP

func _process(delta):
	# Рухаємо кулю в заданому напрямку
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	# Перевіряємо, чи тіло, в яке ми влучили, належить до групи "enemies"
	if body.is_in_group("enemies"):
		body.queue_free() # Знищуємо ворога
		queue_free()      # Знищуємо і саму кулю # Replace with function body.
