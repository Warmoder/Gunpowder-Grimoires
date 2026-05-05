extends Node2D

@onready var light = $PointLight2D
var base_energy: float

func _ready():
	# Запам'ятовуємо базову силу світла, яку ти виставив в інспекторі
	if light:
		base_energy = light.energy
		
func _process(delta):
	# Робимо плавне рандомне мерехтіння
	if light:
		# noise або рандом для зміни energy:
		light.energy = base_energy + randf_range(-0.15, 0.15)
