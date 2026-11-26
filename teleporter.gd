extends Area2D

var is_active = false

func _ready():
	# Спочатку портал прозорий/сірий (вимкнений)
	modulate = Color(0.5, 0.5, 0.5, 0.5)
	GameManager.register_aux_light(get_node_or_null("PointLight2D"), 8.0)

func activate():
	is_active = true
	modulate = Color(1, 1, 2, 1)
	print("Teleporter Activated!")
	
	# Граємо звук відкриття (один раз)
	$ActivateSound.play()
	# Вмикаємо постійний гул
	$HumSound.play()
	_show_portal_banner()

func _show_portal_banner():
	var layer = CanvasLayer.new()
	layer.layer = 100
	var lbl = Label.new()
	lbl.text = "BOSS DEFEATED — PORTAL OPEN!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.anchors_preset = Control.PRESET_TOP_WIDE
	lbl.anchor_left = 0.0
	lbl.anchor_right = 1.0
	lbl.offset_top = 80.0
	lbl.offset_bottom = 130.0
	var font = load("res://text_style.ttf")
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.modulate.a = 0.0
	layer.add_child(lbl)
	get_tree().current_scene.add_child(layer)
	
	var tween = layer.create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.tween_callback(layer.queue_free)

func _on_body_entered(body):
	if is_active and body.is_in_group("player"):
		call_deferred("next_level")

func next_level():
	GameManager.go_to_next_level()
