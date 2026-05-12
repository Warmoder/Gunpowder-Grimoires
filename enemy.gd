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

var player
var last_known_position: Vector2
var is_dead = false

@onready var ray_cast = $RayCast
@onready var base_max_health = health
@onready var base_speed = speed

signal died

func _ready():
	var multiplier = GameManager.get_difficulty_multiplier()
	health = base_max_health * multiplier
	speed = base_speed * multiplier
	last_known_position = global_position
	wander_timer = randf_range(1.0, 1.5)

func _physics_process(delta):
	if is_dead: return
	
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# --- 1. ЗІР (RayCast) ---
	ray_cast.target_position = to_local(player.global_position)
	ray_cast.force_raycast_update()
	
	var can_see_player = false
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider.is_in_group("player"):
			can_see_player = true
	
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
				if global_position.distance_to(last_known_position) <= 20 or get_slide_collision_count() > 0:
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
			
			if global_position.distance_to(wander_target) <= 10:
				current_state = State.WANDER_WAIT
				wander_timer = randf_range(1.0, 1.5)

	# --- 3. ФІЗИКА ТА ВІДШТОВХУВАННЯ ---
	current_knockback = current_knockback.lerp(Vector2.ZERO, 10.0 * delta)
	velocity += current_knockback
	
	move_and_slide()
	
	# Якщо врізалися в стіну під час звичайного блукання
	if get_slide_collision_count() > 0 and current_state == State.WANDER_MOVE:
		current_state = State.WANDER_WAIT
		wander_timer = randf_range(1.0, 1.5)

func pick_random_wander_target():
	var random_angle = randf() * TAU
	var random_dist = randf_range(50.0, 150.0)
	wander_target = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_dist

func take_damage(amount, weapon_type = ""):
	if is_dead: return
	health -= amount

	if health > 0 and player:
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
