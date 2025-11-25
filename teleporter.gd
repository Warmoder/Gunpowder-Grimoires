extends Area2D

var is_active = false

func _ready():
	# Спочатку портал прозорий/сірий (вимкнений)
	modulate = Color(0.5, 0.5, 0.5, 0.5)

func activate():
	is_active = true
	modulate = Color(1, 1, 2, 1)
	print("Teleporter Activated!")
	
	# Граємо звук відкриття (один раз)
	$ActivateSound.play()
	# Вмикаємо постійний гул
	$HumSound.play()

func _on_body_entered(body):
	if is_active and body.is_in_group("player"):
		call_deferred("next_level")

func next_level():
	GameManager.go_to_next_level()
