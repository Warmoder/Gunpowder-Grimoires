extends CharacterBody2D

@export var health = 2
@export var speed = 80.0 
@export var stop_distance = 250.0 
@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@export var muzzle_flash_scene: PackedScene

# --- ДЛЯ ВІДШТОВХУВАННЯ ---
@export var knockback_force: float = 250.0
@export var knockback_resistance: float = 0.0
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

var player
var last_known_position: Vector2
var is_dead = false

signal died

func _ready():
	var multiplier = GameManager.get_difficulty_multiplier()
	health = base_max_health * multiplier
	speed = base_speed * multiplier
	shoot_timer.timeout.connect(fire)
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
				# БАЧИМО ГРАВЦЯ: Дивимось, стріляємо, тримаємо дистанцію
				look_at(player.global_position)
				
				if shoot_timer.is_stopped():
					shoot_timer.start()
					
				var dist_to_player = global_position.distance_to(player.global_position)
				if dist_to_player > stop_distance:
					velocity = global_position.direction_to(player.global_position) * speed
				else:
					velocity = Vector2.ZERO
			else:
				# ВТРАТИЛИ ГРАВЦЯ: Припиняємо вогонь і йдемо до останньої точки
				shoot_timer.stop()
				look_at(last_known_position)
				velocity = global_position.direction_to(last_known_position) * speed
				
				# Якщо дійшли до точки, а гравця немає - вертаємось у патруль
				if global_position.distance_to(last_known_position) <= 15:
					current_state = State.WANDER_WAIT
					wander_timer = randf_range(1.0, 2.0)
				
		State.WANDER_WAIT:
			velocity = Vector2.ZERO
			shoot_timer.stop()
			wander_timer -= delta
			if wander_timer <= 0:
				pick_random_wander_target()
				current_state = State.WANDER_MOVE
				
		State.WANDER_MOVE:
			look_at(wander_target)
			velocity = global_position.direction_to(wander_target) * (speed * 0.6)
			if global_position.distance_to(wander_target) <= 10:
				current_state = State.WANDER_WAIT
				wander_timer = randf_range(1.0, 1.5)

	# --- 3. ФІЗИКА ТА ВІДШТОВХУВАННЯ ---
	current_knockback = current_knockback.lerp(Vector2.ZERO, 10.0 * delta)
	velocity += current_knockback
	
	move_and_slide()
	
	if get_slide_collision_count() > 0 and current_state == State.WANDER_MOVE:
		current_state = State.WANDER_WAIT
		wander_timer = randf_range(1.0, 1.5)

func pick_random_wander_target():
	var random_angle = randf() * TAU
	var random_dist = randf_range(60.0, 200.0)
	wander_target = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_dist

func fire():
	# Стріляємо ТІЛЬКИ якщо ми в стані погоні І бачимо ціль (RayCast оновиться перед пострілом)
	if is_dead or current_state != State.CHASE:
		shoot_timer.stop()
		return
		
	# Подвійна перевірка зору прямо в момент пострілу
	ray_cast.force_raycast_update()
	if not ray_cast.is_colliding() or not ray_cast.get_collider().is_in_group("player"):
		shoot_timer.stop()
		return

	if not bullet_scene: return
	
	var bullet_instance = bullet_scene.instantiate()
	get_tree().root.add_child(bullet_instance)
	
	bullet_instance.global_position = $Sprite2D/Muzzle.global_position
	bullet_instance.rotation = global_rotation
	bullet_instance.direction = transform.x

	if muzzle_flash_scene:
		var flash = muzzle_flash_scene.instantiate()
		$Sprite2D/Muzzle.add_child(flash)

	shoot_sound.play()

func take_damage(amount, weapon_type = ""):
	if is_dead: return
	health -= amount
	
	if health > 0 and player:
		var knockback_dir = (global_position - player.global_position).normalized()
		var actual_force = knockback_force * (1.0 - knockback_resistance)
		current_knockback = knockback_dir * actual_force

	if health <= 0:
		is_dead = true 
		drop_loot()
		emit_signal("died")
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			get_tree().root.add_child(explosion)
			explosion.global_position = global_position
			explosion.emitting = true
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
