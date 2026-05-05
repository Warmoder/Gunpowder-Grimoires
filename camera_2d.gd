extends Camera2D

var player

func _ready():
	# Шукаємо гравця в групі
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if player:
		# Просто копіюємо позицію гравця
		global_position = player.global_position
