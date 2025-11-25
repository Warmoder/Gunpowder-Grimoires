extends Area2D

var speed = 1000.0
# Ця змінна чекає, поки гравець або ворог її заповнить
var direction = Vector2.ZERO
var damage = 1

func _process(delta):
	# Ми рухаємо кулю вздовж цього напрямку
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage) # Передаємо шкоду ворогу
	
	queue_free()
