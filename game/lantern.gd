extends Node2D

@onready var light = $PointLight2D
@onready var enabler = $PointLight2D/VisibleOnScreenEnabler2D
var base_energy: float
var flicker_timer: float = 0.0

func _ready():
	add_to_group("lanterns")
	if light:
		base_energy = light.energy
	if enabler:
		enabler.screen_entered.connect(_on_screen_entered)
		enabler.screen_exited.connect(_on_screen_exited)
	update_graphics_settings()

func update_graphics_settings():
	if not light:
		return
	var normal_maps = GameManager.settings_data.get("normal_maps", true)
	var lanterns_light = GameManager.settings_data.get("lanterns_light", true)
	light.height = 59.0 if normal_maps else 0.0
	if not lanterns_light:
		light.enabled = false
		set_process(false)
	else:
		var on_screen = enabler.is_on_screen() if enabler else true
		light.enabled = on_screen
		set_process(on_screen)

func _on_screen_entered():
	var lanterns_light = GameManager.settings_data.get("lanterns_light", true)
	if light and lanterns_light:
		light.enabled = true
	set_process(lanterns_light)

func _on_screen_exited():
	if light:
		light.enabled = false
	set_process(false)

func _process(delta):
	# Мерехтіння лише для активних ліхтарів
	flicker_timer += delta
	if flicker_timer >= 0.08:
		flicker_timer = 0.0
		if light and light.enabled:
			light.energy = base_energy + randf_range(-0.12, 0.12)
