extends Area2D

@export var heal_amount = 1

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Перевіряємо, чи є у гравця функція лікування
		if body.has_method("heal"):
			body.heal(heal_amount)
		
		# Граємо звук
		$PickupSound.play()
		
		# Ховаємо спрайт і вимикаємо колізію (щоб не підібрати двічі)
		$Sprite2D.hide()
		$CollisionShape2D.set_deferred("disabled", true)
		
		# Чекаємо, поки звук закінчиться
		await $PickupSound.finished
		
		# Тепер можна видаляти
		queue_free()
