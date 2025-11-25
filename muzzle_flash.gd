extends GPUParticles2D

func _ready():
	emitting = true # Автозапуск
	finished.connect(queue_free) # Самознищення
