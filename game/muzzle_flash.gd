extends GPUParticles2D

func _ready():
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var light = get_node_or_null("PointLight2D")
	if light and GameManager.settings_data.get("graphics_quality", 1) == 0:
		light.enabled = false
	emitting = true # Автозапуск
	finished.connect(queue_free) # Самознищення
