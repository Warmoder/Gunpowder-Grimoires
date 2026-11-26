extends CharacterBody2D

@export var health = 3
@export var speed = 150.0
@export var explosion_scene: PackedScene

# --- ДЛЯ ВІДШТОВХУВАННЯ ---
@export var knockback_force: float = 300.0
@export var knockback_resistance: float = 0.0 
var current_knockback: Vector2 = Vector2.ZERO

# --- ШТУЧНИЙ ІНТЕЛЕКТ ---
enum State { WANDER_WAIT, WANDER_MOVE, CHASE }
var current_state = State.WANDER_WAIT
var wander_timer: float = 0.0
var wander_target: Vector2 = Vector2.ZERO

const VISION_RANGE_SQ: float = 950.0 * 950.0
const RAYCAST_INTERVAL: float = 0.12
var raycast_timer: float = 0.0
var can_see_player: bool = false

var player
var last_known_position: Vector2
var is_dead = false

@onready var ray_cast = $RayCast
@onready var base_max_health = health
@onready var base_speed = speed
@onready var point_light = get_node_or_null("PointLight2D")

signal died

func _ready():
	var multiplier = GameManager.get_difficulty_multiplier()
	health = base_max_health * multiplier
	speed = base_speed * multiplier
	last_known_position = global_position
	wander_timer = randf_range(1.0, 1.5)
	raycast_timer = randf_range(0.0, RAYCAST_INTERVAL)
	_setup_light()

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
			
	match current_state:
		State.CHASE:
			if can_see_player:
				# БАЧИМО ГРАВЦЯ: Біжимо прямо на нього
				look_at(player.global_position)
				var direction = global_position.direction_to(player.global_position)
				velocity = direction * speed
			else:
				# ВТРАТИЛИ ГРАВЦЯ: Йдемо до останньої відомої точки
				look_at(last_known_position)
				var direction = global_position.direction_to(last_known_position)
				velocity = direction * speed
				
				# ФІКС: Якщо дійшли АБО врізалися в стіну/кут — вертаємось у патруль
				if global_position.distance_squared_to(last_known_position) <= 400.0 or get_slide_collision_count() > 0:
					current_state = State.WANDER_WAIT
					wander_timer = randf_range(1.0, 2.0)
			
		State.WANDER_WAIT:
			velocity = Vector2.ZERO
			wander_timer -= delta
			if wander_timer <= 0:
				pick_random_wander_target()
				current_state = State.WANDER_MOVE
				
		State.WANDER_MOVE:
			look_at(wander_target)
			var direction = global_position.direction_to(wander_target)
			velocity = direction * (speed * 0.5)
			
			if global_position.distance_squared_to(wander_target) <= 100.0:
				current_state = State.WANDER_WAIT
				wander_timer = randf_range(1.0, 1.5)

	# --- 3. ФІЗИКА ТА ВІДШТОВХУВАННЯ ---
	var has_knockback = current_knockback.length_squared() > 1.0
	if has_knockback:
		current_knockback = current_knockback.lerp(Vector2.ZERO, 10.0 * delta)
		velocity += current_knockback
	else:
		current_knockback = Vector2.ZERO
	
	if velocity != Vector2.ZERO:
		move_and_slide()
		# Якщо врізалися в стіну під час звичайного блукання
		if get_slide_collision_count() > 0 and current_state == State.WANDER_MOVE:
			current_state = State.WANDER_WAIT
			wander_timer = randf_range(1.0, 1.5)

func pick_random_wander_target():
	var random_angle = randf() * TAU
	var random_dist = randf_range(50.0, 150.0)
	wander_target = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_dist

func _flash_hit():
	var spr = get_node_or_null("Sprite2D")
	if not spr: return
	spr.modulate = Color(2.2, 2.2, 2.2, 1.0)
	var tween = create_tween()
	tween.tween_property(spr, "modulate", Color.WHITE, 0.08)

func take_damage(amount, weapon_type = ""):
	if is_dead: return
	health -= amount
	GameManager.spawn_damage_number(global_position, amount, amount >= 2.0)

	if health > 0:
		_flash_hit()
		if player:
			var knockback_dir = (global_position - player.global_position).normalized()
			var actual_force = knockback_force * (1.0 - knockback_resistance)
			current_knockback = knockback_dir * actual_force

	if health <= 0:
		is_dead = true 
		emit_signal("died")
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			get_tree().root.add_child(explosion)
			explosion.global_position = global_position
			explosion.emitting = true
		drop_loot()
		queue_free()

func _on_attack_area_body_entered(body):
	if body.has_method("die"):
		var damage_success = body.die()
		if damage_success:
			queue_free()

func drop_loot():
	var loot_scene = GameManager.get_random_loot()
	if loot_scene:
		var loot = loot_scene.instantiate()
		get_tree().root.call_deferred("add_child", loot)
		loot.global_position = global_position
