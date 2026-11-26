extends Area2D

func _ready():
	GameManager.register_aux_light(get_node_or_null("PointLight2D"), 8.0)

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("activate_shield"):
		
		# 1. Активуємо ефект
		body.activate_shield()
		
		# 2. Граємо звук
		$PickupSound.play()
		
		# 3. Ховаємо спрайт, світло і вимикаємо колізію (щоб не підібрати двічі)
		$Sprite2D.hide()
		var light = get_node_or_null("PointLight2D")
		if light: light.enabled = false
		$CollisionShape2D.set_deferred("disabled", true)
		
		# 4. Чекаємо, поки звук закінчиться
		await $PickupSound.finished
		
		# 5. Тепер можна видаляти
		if is_inside_tree():
			queue_free()
