extends GPUParticles2D

func _ready():
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func _on_finished():
	queue_free() # Знищуємо себе, коли ефект закінчився
