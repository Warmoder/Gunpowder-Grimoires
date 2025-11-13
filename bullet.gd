extends Area2D

var damage = 1
# Швидкість кулі в пікселях за секунду
var speed = 1000.0
# Напрямок, в якому летить куля. Його задасть гравець при пострілі.
var direction = Vector2.UP

func _process(delta):
	# Рухаємо кулю в заданому напрямку
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage) # Передаємо шкоду ворогу
	
	queue_free()
