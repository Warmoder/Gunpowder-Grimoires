extends Area2D

var speed = 1200.0 # Дріб летить швидше, але недовго
var direction = Vector2.ZERO
var damage = 1
var weapon_type = "shotgun"

func _ready():
	# Створюємо таймер, який знищить дробинку через 0.3 секунди
	var timer = get_tree().create_timer(0.3)
	await timer.timeout
	# Можна додати плавне зникнення перед видаленням
	queue_free()

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		# Передаємо і шкоду, і свій тип
		body.take_damage(damage, weapon_type)
	queue_free()
