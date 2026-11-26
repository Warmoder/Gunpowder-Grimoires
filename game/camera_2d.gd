extends Camera2D

var shake_strength: float = 0.0
var shake_fade: float = 5.0
var look_ahead_offset: Vector2 = Vector2.ZERO
const LOOK_AHEAD_FACTOR: float = 0.06
const LOOK_AHEAD_MAX: float = 38.0
const LOOK_AHEAD_SMOOTH: float = 8.0
var _is_android: bool = false

func _ready():
	_is_android = (OS.get_name() == "Android")
	var z = clampf(float(GameManager.settings_data.get("camera_zoom", 1.0)), 0.6, 1.4)
	zoom = Vector2(z, z)

func apply_shake(strength: float):
	shake_strength = strength

func _process(delta):
	var target_look = Vector2.ZERO
	if not _is_android:
		var viewport_size = get_viewport_rect().size
		if viewport_size.x > 0 and viewport_size.y > 0:
			var mouse_delta = get_viewport().get_mouse_position() - (viewport_size * 0.5)
			target_look = (mouse_delta * LOOK_AHEAD_FACTOR).limit_length(LOOK_AHEAD_MAX)
	
	look_ahead_offset = look_ahead_offset.lerp(target_look, minf(1.0, LOOK_AHEAD_SMOOTH * delta))
	
	var shake_offset = Vector2.ZERO
	if shake_strength > 0.0:
		shake_strength = lerpf(shake_strength, 0.0, shake_fade * delta)
		if shake_strength < 0.05:
			shake_strength = 0.0
		else:
			shake_offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	
	offset = look_ahead_offset + shake_offset
