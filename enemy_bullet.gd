extends Area2D

var speed = 800.0 # Можна зробити їх трохи повільнішими за кулі гравця
var direction = Vector2.UP
var damage = 1

func _process(delta):
	position += direction * speed * delta

# Ця функція спрацює при зіткненні і з гравцем, і зі стіною
func _on_body_entered(body):
	# Перевіряємо, чи влучили ми в гравця
	if body.has_method("die"): # У гравця є метод "die"
		body.die() # Кажемо гравцю "отримай шкоду"
	
	# У будь-якому випадку (гравець чи стіна), куля зникає
	queue_free()
