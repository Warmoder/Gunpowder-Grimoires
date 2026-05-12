extends Area2D

@export var pierce_count: int = 2 # Скількох ворогів прошиє наскрізь (2 означає, що вб'є першого, пройде крізь нього і влучить у другого)

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
	# Якщо це стіна (TileMapLayer) або будь-яка інша статична перешкода — куля зникає одразу
	if body is TileMapLayer or not body.is_in_group("enemies"):
		queue_free()
		return
		
	# Якщо це ворог
	if body.has_method("take_damage"):
		body.take_damage(damage, weapon_type)
		
		# Зменшуємо "силу пробивання" на 1
		pierce_count -= 1
		
		# Якщо пробивна сила закінчилася (прошили 2-х ворогів), знищуємо кулю
		if pierce_count <= 0:
			queue_free()
