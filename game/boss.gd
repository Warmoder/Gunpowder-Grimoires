extends CharacterBody2D

@export var health = 24
@export var speed = 70.0
@export var stop_distance = 200.0

@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@export var muzzle_flash_scene: PackedScene

# --- ДЛЯ ВІДШТОВХУВАННЯ ---
@export var knockback_force: float = 150.0
@export var knockback_resistance: float = 0.9 
var current_knockback: Vector2 = Vector2.ZERO

# --- ШТУЧНИЙ ІНТЕЛЕКТ ---
enum State { WANDER_WAIT, WANDER_MOVE, CHASE }
var current_state = State.WANDER_WAIT
var wander_timer: float = 0.0
var wander_target: Vector2 = Vector2.ZERO

@onready var shoot_sound = $ShootSound
@onready var ray_cast = $RayCast
@onready var shoot_timer = $ShootTimer
@onready var base_max_health = health
@onready var base_speed = speed
@onready var muzzle = $Sprite2D/Muzzle
@onready var point_light = get_node_or_null("PointLight2D")

const VISION_RANGE_SQ: float = 1100.0 * 1100.0
const RAYCAST_INTERVAL: float = 0.1
var raycast_timer: float = 0.0
var stop_distance_sq: float = 0.0

var player
var last_known_position: Vector2
var is_dead = false
var can_see_player = false # Змінна для перевірки зору в поточному кадрі
var max_health: float = 24.0
var _boss_bar_layer: CanvasLayer = null
var _boss_bar: ProgressBar = null
var _boss_bar_label: Label = null

signal died

func _ready():
	add_to_group("boss")
	var multiplier = GameManager.get_difficulty_multiplier()
	health = base_max_health * multiplier
	max_health = health
	speed = base_speed * multiplier
	stop_distance_sq = stop_distance * stop_distance
	
	shoot_timer.timeout.connect(fire)
	last_known_position = global_position
	wander_timer = randf_range(2.0, 3.0)
	_setup_light()

func _ensure_boss_bar():
	if _boss_bar_layer and is_instance_valid(_boss_bar_layer):
		return
	var scene = get_tree().current_scene
	if not scene: return
	_boss_bar_layer = CanvasLayer.new()
	_boss_bar_layer.layer = 80
	
	var container = VBoxContainer.new()
	container.anchors_preset = Control.PRESET_TOP_WIDE
	container.anchor_left = 0.25
	container.anchor_right = 0.75
	container.offset_top = 18.0
	container.offset_bottom = 76.0
	container.add_theme_constant_override("separation", 4)
	_boss_bar_layer.add_child(container)
	
	_boss_bar_label = Label.new()
	_boss_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font = load("res://text_style.ttf")
	if font:
		_boss_bar_label.add_theme_font_override("font", font)
	_boss_bar_label.add_theme_font_size_override("font_size", 22)
	_boss_bar_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.95))
	_boss_bar_label.add_theme_constant_override("outline_size", 3)
	_boss_bar_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	container.add_child(_boss_bar_label)
	
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(0, 20)
	_boss_bar.max_value = max_health
	_boss_bar.value = health
	_boss_bar.show_percentage = false
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.04, 0.14, 0.88)
	bg_style.border_color = Color(0.75, 0.2, 0.85, 0.9)
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(4)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.88, 0.15, 0.45, 0.95)
	fill_style.set_corner_radius_all(3)
	_boss_bar.add_theme_stylebox_override("background", bg_style)
	_boss_bar.add_theme_stylebox_override("fill", fill_style)
	container.add_child(_boss_bar)
	
	scene.add_child(_boss_bar_layer)
	_update_boss_bar()

func _update_boss_bar():
	if _boss_bar and is_instance_valid(_boss_bar):
		_boss_bar.max_value = max_health
		_boss_bar.value = maxf(0.0, health)
	if _boss_bar_label and is_instance_valid(_boss_bar_label):
		_boss_bar_label.text = "BOSS  (%d / %d)" % [ceili(maxf(0.0, health)), ceili(max_health)]

func _remove_boss_bar():
	if _boss_bar_layer and is_instance_valid(_boss_bar_layer):
		_boss_bar_layer.queue_free()
		_boss_bar_layer = null

func _setup_light():
	if not point_light: return
	point_light.add_to_group("aux_lights")
	var quality = GameManager.settings_data.get("graphics_quality", 1)
	var normal_maps = GameManager.settings_data.get("normal_maps", true)
	point_light.height = 26.0 if normal_maps else 0.0
	var enabler = point_light.get_node_or_null("VisibleOnScreenEnabler2D")
	if enabler:
		enabler.screen_entered.connect(func():
			if GameManager.settings_data.get("graphics_quality", 1) != 0:
				point_light.enabled = true
		)
		enabler.screen_exited.connect(func(): point_light.enabled = false)
		point_light.enabled = (quality != 0 and enabler.is_on_screen())
	else:
		point_light.enabled = (quality != 0)

func _physics_process(delta):
	if is_dead: return

	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# --- 1. ЗІР (RayCast з тротлінгом та обмеженням дистанції) ---
	raycast_timer -= delta
	if raycast_timer <= 0.0:
		raycast_timer = RAYCAST_INTERVAL
		if global_position.distance_squared_to(player.global_position) <= VISION_RANGE_SQ:
			ray_cast.target_position = to_local(player.global_position)
			ray_cast.force_raycast_update()
			can_see_player = false
			if ray_cast.is_colliding():
				var collider = ray_cast.get_collider()
				if collider and collider.is_in_group("player"):
					can_see_player = true
		else:
			can_see_player = false
	
	# --- 2. ЛОГІКА СТАНІВ ---
	if can_see_player:
		current_state = State.CHASE
		last_known_position = player.global_position
		_ensure_boss_bar()

	match current_state:
		State.CHASE:
			if can_see_player:
				# БАЧИМО ГРАВЦЯ
				look_at(player.global_position)
				
				if shoot_timer.is_stopped():
					shoot_timer.start()
					
				if global_position.distance_squared_to(player.global_position) > stop_distance_sq:
					velocity = global_position.direction_to(player.global_position) * speed
				else:
					velocity = Vector2.ZERO
			else:
				# ВТРАТИЛИ ГРАВЦЯ: Йдемо до останньої відомої точки
				shoot_timer.stop()
				look_at(last_known_position)
				velocity = global_position.direction_to(last_known_position) * speed
				
				# ФІКС: Якщо прийшли в точку АБО врізалися в стіну — вертаємось у патруль
				if global_position.distance_squared_to(last_known_position) <= 400.0 or get_slide_collision_count() > 0:
					current_state = State.WANDER_WAIT
					wander_timer = randf_range(1.5, 2.5)
				
		State.WANDER_WAIT:
			velocity = Vector2.ZERO
			shoot_timer.stop()
			wander_timer -= delta
			if wander_timer <= 0:
				pick_random_wander_target()
				current_state = State.WANDER_MOVE
				
		State.WANDER_MOVE:
			look_at(wander_target)
			var direction = global_position.direction_to(wander_target)
			velocity = direction * (speed * 0.7)
			
			if global_position.distance_squared_to(wander_target) <= 225.0:
				current_state = State.WANDER_WAIT
				wander_timer = randf_range(1.5, 2.5)

	# --- 3. ФІЗИКА ТА ВІДШТОВХУВАННЯ ---
	var has_knockback = current_knockback.length_squared() > 1.0
	if has_knockback:
		current_knockback = current_knockback.lerp(Vector2.ZERO, 8.0 * delta)
		velocity += current_knockback
	else:
		current_knockback = Vector2.ZERO
	
	if velocity != Vector2.ZERO:
		move_and_slide()
		# Перевірка на зіткнення зі стіною під час звичайного блукання
		if get_slide_collision_count() > 0 and current_state == State.WANDER_MOVE:
			current_state = State.WANDER_WAIT
			wander_timer = randf_range(1.0, 2.0)

func pick_random_wander_target():
	var random_angle = randf() * TAU
	var random_dist = randf_range(100.0, 300.0)
	wander_target = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_dist

func fire():
	if is_dead or current_state != State.CHASE or not can_see_player: 
		shoot_timer.stop()
		return
	
	if not bullet_scene: return
	
	var bullet_instance = bullet_scene.instantiate()
	bullet_instance.global_position = muzzle.global_position
	bullet_instance.rotation = global_rotation
	bullet_instance.direction = transform.x
	if get_tree().current_scene:
		get_tree().current_scene.add_child(bullet_instance)
		bullet_instance.reset_physics_interpolation()

	if muzzle_flash_scene:
		var flash = muzzle_flash_scene.instantiate()
		muzzle.add_child(flash)

	shoot_sound.play()

func _flash_hit():
	var spr = get_node_or_null("Sprite2D")
	if not spr: return
	spr.modulate = Color(2.2, 2.2, 2.2, 1.0)
	var tween = create_tween()
	tween.tween_property(spr, "modulate", Color.WHITE, 0.08)

func take_damage(amount, weapon_type = ""):
	if is_dead: return
	
	var final_damage = amount
	if weapon_type == "shotgun":
		final_damage = amount * 0.25 
	
	health -= final_damage
	GameManager.spawn_damage_number(global_position, final_damage, final_damage >= 2.0)
	_ensure_boss_bar()
	_update_boss_bar()
	
	if health > 0:
		_flash_hit()
		if player:
			var knockback_dir = (global_position - player.global_position).normalized()
			var actual_force = knockback_force * (1.0 - knockback_resistance)
			current_knockback = knockback_dir * actual_force

	if health <= 0:
		is_dead = true
		_remove_boss_bar()
		drop_loot()
		GameManager.unlock_achievement("boss_killer", "Boss Killer!")
		emit_signal("died")
		
		if explosion_scene and get_tree().current_scene:
			var explosion = explosion_scene.instantiate()
			explosion.global_position = global_position
			get_tree().current_scene.add_child(explosion)
			explosion.emitting = true
		
		queue_free()

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		if "has_shield" in body and body.has_shield:
			body.die()
		else:
			if "current_health" in body:
				body.current_health = 0
			body.die()

func drop_loot():
	var buff_scene = null
	var roll = randi() % 3
	if roll == 0: buff_scene = GameManager.damage_up
	elif roll == 1: buff_scene = GameManager.speed_up
	else: buff_scene = GameManager.shield
		
	if not get_tree().current_scene: return
	var buff = buff_scene.instantiate()
	buff.global_position = global_position + Vector2(-15, -15)
	get_tree().current_scene.call_deferred("add_child", buff)

	var potion = GameManager.health_potion.instantiate()
	potion.global_position = global_position + Vector2(15, 15)
	get_tree().current_scene.call_deferred("add_child", potion)
