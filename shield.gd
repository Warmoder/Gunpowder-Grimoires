extends Area2D

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("activate_shield"):
		body.activate_shield()
		queue_free()
