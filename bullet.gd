extends Area2D

var speed = 1000.0
# Ця змінна чекає, поки гравець або ворог її заповнить
var direction = Vector2.ZERO
var damage = 1
var weapon_type = "pistol"

func _process(delta):
	# Ми рухаємо кулю вздовж цього напрямку
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		# Передаємо і шкоду, і свій тип
		body.take_damage(damage, weapon_type)
	queue_free()
