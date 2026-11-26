extends CharacterBody2D

# --- ЗМІННІ ---

# Експортовані змінні (налаштовуються в редакторі)
@export var speed = 400.0
@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@export var pixels_per_step = 120.0
@export var muzzle_flash_scene: PackedScene
@export var shotgun_pellet_scene: PackedScene
@export var rifle_bullet_scene: PackedScene

# Посилання на дочірні вузли (ініціалізуються при старті)
@onready var shoot_timer = $ShootTimer
@onready var shoot_sound = $ShootSound
@onready var hitbox = $Hitbox
@onready var shield_sprite = $ShieldSprite
@onready var footstep_sound = $FootstepSound
@onready var step_timer = $StepTimer
@onready var sprite = $Sprite2D # Посилання на спрайт для блимання
@onready var muzzle = $Sprite2D/Muzzle
@onready var camera = $CollisionShape2D/Camera2D
@onready var switch_weapon_timer = $SwitchWeaponTimer

var is_android: bool = false

# Ігрові змінні
var current_health: int
var base_damage = 1
var has_shield = false
var base_speed: float
var speed_boost_count = 0
var damage_boost_count = 0
var is_invincible = false

# Час, що залишився для візуалізації бонусів
var speed_time_left: float = 0.0
var damage_time_left: float = 0.0
var stats_ui_timer: float = 0.0

var move_stick
var shoot_stick

# Масив словників зброї
var weapons_data = []
var current_weapon_index = 0
var current_weapon_data = {}
var current_weapon_scene

# --- МАГІЯ (Гримуари) ---
var heal_cooldown: float = 0.0
var magic_cooldown: float = 0.0
var heal_sound_stream = preload("res://heal_magic_sound.mp3")
var random_magic_sound_stream = preload("res://random_magic_sound.wav")

signal health_changed(current_health, max_health)
signal player_healed
signal stats_updated(damage_mult, damage_time, current_speed, speed_time)
signal player_damaged
signal weapon_changed(weapon_name)

# --- ВБУДОВАНІ ФУНКЦІЇ GODOT ---

func _ready():
	# --- 1. ІНІЦІАЛІЗАЦІЯ ТА ВІДНОВЛЕННЯ СТАТІВ МІЖ РІВНЯМИ ---
	current_health = GameManager.current_health if GameManager.current_health > 0 else GameManager.base_health
	GameManager.current_health = current_health
	health_changed.emit(current_health, GameManager.max_health)
	base_speed = speed
	heal_cooldown = GameManager.saved_heal_cooldown
	magic_cooldown = GameManager.saved_magic_cooldown

	# --- 2. НАЛАШТУВАННЯ ЗБРОЇ ТА ТЕКСТУР ---
	var default_shoot_sound = preload("res://shoot.wav")
	var shotgun_shoot_sound = preload("res://shotgun_shoot.wav")
	var rifle_shoot_sound = preload("res://rifle_sound.wav")

	var tex_pistol = preload("res://player_tex_pistol.tres") if ResourceLoader.exists("res://player_tex_pistol.tres") else sprite.texture
	var tex_shotgun = preload("res://player_tex_shotgun.tres") if ResourceLoader.exists("res://player_tex_shotgun.tres") else sprite.texture
	var tex_rifle = preload("res://player_tex_rifle.tres") if ResourceLoader.exists("res://player_tex_rifle.tres") else sprite.texture

	weapons_data = [
		{
			"name": "Pistol",
			"scene": bullet_scene,
			"fire_rate": 0.4,
			"sound": default_shoot_sound,
			"texture": tex_pistol
		},
		{
			"name": "Shotgun",
			"scene": shotgun_pellet_scene,
			"fire_rate": 1.2,
			"sound": shotgun_shoot_sound,
			"texture": tex_shotgun
		},
		{
			"name": "Rifle",
			"scene": rifle_bullet_scene if rifle_bullet_scene else bullet_scene,
			"fire_rate": 0.1,
			"sound": rifle_shoot_sound,
			"texture": tex_rifle
		}
	]
	
	switch_weapon(GameManager.saved_weapon_index)
	
	# Відновлюємо щит та активні бафи з попереднього рівня
	if GameManager.saved_has_shield:
		activate_shield(false)
	if GameManager.saved_speed_time_left > 0.2:
		boost_speed(GameManager.saved_speed_time_left, false)
	if GameManager.saved_damage_time_left > 0.2:
		boost_damage(GameManager.saved_damage_time_left, false)

	# --- 3. ІНІЦІАЛІЗАЦІЯ КЕРУВАННЯ (Android) ---
	is_android = (OS.get_name() == "Android")
	if is_android:
		move_stick = get_tree().root.get_node_or_null("Map/TouchControls/MoveStick")
		shoot_stick = get_tree().root.get_node_or_null("Map/TouchControls/ShootStick")

func _process(delta):
	# --- 1. ЛОГІКА ПОВОРОТУ ---
	if is_android and shoot_stick:
		if shoot_stick.is_pressed:
			rotation = shoot_stick.output.angle()
	else:
		var direction_to_mouse = get_global_mouse_position() - global_position
		rotation = direction_to_mouse.angle()

	# --- 2. ОНОВЛЕННЯ ТАЙМЕРІВ ---
	if speed_boost_count > 0: speed_time_left -= delta
	else: speed_time_left = 0
		
	if damage_boost_count > 0: damage_time_left -= delta
	else: damage_time_left = 0
		
	if heal_cooldown > 0: heal_cooldown -= delta
	if magic_cooldown > 0: magic_cooldown -= delta
		
	# --- 3. ВІДПРАВКА ДАНИХ В UI (Тротлінг до 10 FPS для економії CPU) ---
	stats_ui_timer += delta
	if stats_ui_timer >= 0.1:
		stats_ui_timer = 0.0
		var current_mult = 1.0 + damage_boost_count
		stats_updated.emit(current_mult, damage_time_left, speed, speed_time_left)

func _physics_process(_delta):
	# --- 1. ОТРИМАННЯ НАПРЯМКУ РУХУ ---
	var direction = Vector2.ZERO
	if is_android and move_stick:
		direction = move_stick.output
	else:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# --- 2. РУХ ---
	velocity = direction * speed
	move_and_slide()
	
	# --- 3. ЗВУК КРОКІВ ---
	var speed_sq = velocity.length_squared()
	if speed_sq > 0.01:
		if step_timer.is_stopped():
			footstep_sound.pitch_scale = randf_range(0.9, 1.1)
			footstep_sound.play()
			var step_time = pixels_per_step / sqrt(speed_sq)
			step_timer.start(step_time)
	else:
		step_timer.stop()
	
	# --- 4. ЛОГІКА СТРІЛЬБИ ---
	var is_shooting = false
	if is_android and shoot_stick:
		if shoot_stick.output.length_squared() > 0.0: is_shooting = true
	else:
		is_shooting = Input.is_action_pressed("fire")
	
	if is_shooting and shoot_timer.is_stopped():
		fire()
		
	# --- 5. ЛОГІКА МАГІЇ ТА ЗБРОЇ (Кнопки / Touch Buttons) ---
	if Input.is_action_just_pressed("magic_heal") and heal_cooldown <= 0:
		heal(1)
		heal_cooldown = 45.0
		play_magic_sound(heal_sound_stream)
		
	if Input.is_action_just_pressed("magic_random") and magic_cooldown <= 0:
		cast_random_magic()
		magic_cooldown = 30.0
		play_magic_sound(random_magic_sound_stream)
		
	# НОВЕ: Перевірка зміни зброї перенесена сюди для мобілок
	if Input.is_action_just_pressed("switch_weapon") and switch_weapon_timer.is_stopped():
		switch_weapon((current_weapon_index + 1) % weapons_data.size())
		switch_weapon_timer.start()

func fire():
	if not current_weapon_scene: return
	
	var w_name = current_weapon_data["name"]
	
	if w_name == "Pistol":
		spawn_bullet(current_weapon_scene, 2.0, 0.0)
		camera.apply_shake(3.0) # Легка віддача
		
	elif w_name == "Shotgun":
		var pellet_count = 5
		var spread_angle = 25.0
		for i in range(pellet_count):
			var angle_offset = randf_range(-spread_angle / 2, spread_angle / 2)
			var final_angle = rotation + deg_to_rad(angle_offset)
			spawn_pellet(current_weapon_scene, final_angle)
		camera.apply_shake(10.0) # Жорстке трясіння
			
	elif w_name == "Rifle":
		var spread_angle = 15.0
		var angle_offset = randf_range(-spread_angle / 2, spread_angle / 2)
		spawn_bullet(current_weapon_scene, 0.3, angle_offset)
		camera.apply_shake(2.0) # Мікро-вібрація від автомата

	if muzzle_flash_scene:
		var flash = muzzle_flash_scene.instantiate()
		muzzle.add_child(flash)

	# --- ЗВУК: ПІТЧ ТА ГУЧНІСТЬ ---
	
	# Робимо рандомний пітч для ВСІЄЇ зброї (від 0.9 до 1.15)
	shoot_sound.pitch_scale = randf_range(0.9, 1.15)
	
	# Контроль гучності (Автомат робимо тихішим, інше - стандартно)
	if w_name == "Rifle":
		shoot_sound.volume_db = -10.0 # Робимо тихіше на 10 децибел (якщо все ще гучно, постав -12.0 або -15.0)
	else:
		shoot_sound.volume_db = 0.0   # Стандартна гучність для пістолета і дробовика

	shoot_sound.play()
	shoot_timer.start()

# --- ДОПОМІЖНІ ФУНКЦІЇ ---

func spawn_bullet(scene, dmg_mult = 1.0, angle_offset_deg = 0.0):
	var bullet = scene.instantiate()
	var multiplier = 1.0 + damage_boost_count
	if "damage" in bullet:
		bullet.damage = (base_damage * dmg_mult) * multiplier
		
	var final_angle = global_rotation + deg_to_rad(angle_offset_deg)
	bullet.global_position = muzzle.global_position
	bullet.rotation = final_angle
	bullet.direction = Vector2.from_angle(final_angle)
	get_tree().root.add_child(bullet)
	bullet.reset_physics_interpolation()

func spawn_pellet(scene, angle_rad):
	var pellet = scene.instantiate()
	var multiplier = 1.0 + damage_boost_count
	if "damage" in pellet:
		pellet.damage = 1 * multiplier
		
	pellet.global_position = muzzle.global_position
	pellet.rotation = angle_rad
	pellet.direction = Vector2.from_angle(angle_rad)
	get_tree().root.add_child(pellet)
	pellet.reset_physics_interpolation()

func die() -> bool:
	if is_invincible: return false
		
	if has_shield:
		has_shield = false
		shield_sprite.hide()
		start_invincibility(1.0)
		return true
	
	current_health -= 1
	GameManager.current_health = current_health
	health_changed.emit(current_health, GameManager.max_health)
	player_damaged.emit()
	
	if current_health <= 0:
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			get_tree().root.add_child(explosion)
			explosion.global_position = global_position
			explosion.emitting = true
		var map = get_tree().current_scene
		if map and map.has_method("game_over"):
			map.game_over()
		elif get_tree().root.has_node("Map"):
			get_tree().root.get_node("Map").game_over()
		hide()
	else:
		start_invincibility(2.0)
		
	return true

func heal(amount):
	current_health += amount
	if current_health > GameManager.max_health:
		current_health = GameManager.max_health
	GameManager.current_health = current_health
	health_changed.emit(current_health, GameManager.max_health)
	player_healed.emit()
	GameManager.spawn_floating_text(global_position, "+%d HP" % amount, Color(0.3, 1.0, 0.45), 1.05)

func cast_random_magic():
	var roll = randi() % 3
	if roll == 0:
		boost_speed(5.0)
	elif roll == 1:
		boost_damage(5.0)
	else:
		activate_shield()

func play_magic_sound(stream: AudioStream):
	if stream == null: return
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "SFX"
	
	# РОБИМО ТИХІШЕ! 
	# Було 2.0, ставимо від'ємне значення. Чим менше число, тим тихіше.
	p.volume_db = -8.0 
	
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func boost_speed(duration, show_text: bool = true):
	speed_boost_count += 1
	speed_time_left = duration
	update_speed()
	if show_text:
		GameManager.spawn_floating_text(global_position, "SPEED UP!", Color(0.4, 0.9, 1.0), 1.05)
	await get_tree().create_timer(duration).timeout
	if not is_inside_tree(): return
	speed_boost_count -= 1
	update_speed()

func boost_damage(duration, show_text: bool = true):
	damage_boost_count += 1
	damage_time_left = duration
	if show_text:
		GameManager.spawn_floating_text(global_position, "DAMAGE x%d!" % (1 + damage_boost_count), Color(1.0, 0.45, 0.2), 1.1)
	await get_tree().create_timer(duration).timeout
	if not is_inside_tree(): return
	damage_boost_count -= 1

func start_invincibility(duration):
	is_invincible = true
	var tween = create_tween().set_loops(8)
	tween.tween_property(sprite, "modulate:a", 0.5, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(duration).timeout
	if not is_inside_tree(): return
	is_invincible = false
	sprite.modulate.a = 1.0

func update_speed():
	var speed_multiplier = 1.0 + (speed_boost_count * 0.4)
	speed = base_speed * speed_multiplier

func activate_shield(show_text: bool = true):
	has_shield = true
	shield_sprite.show()
	if show_text:
		GameManager.spawn_floating_text(global_position, "SHIELD!", Color(0.45, 0.75, 1.0), 1.05)

func switch_weapon(index):
	if index >= 0 and index < weapons_data.size():
		current_weapon_index = index
		current_weapon_data = weapons_data[current_weapon_index]
		current_weapon_scene = current_weapon_data["scene"]
		
		shoot_timer.wait_time = current_weapon_data["fire_rate"]
		shoot_sound.stream = current_weapon_data["sound"]
		
		if current_weapon_data["texture"] != null:
			sprite.texture = current_weapon_data["texture"]
		
		weapon_changed.emit(current_weapon_data["name"])

func _input(event):
	if not switch_weapon_timer.is_stopped(): return

	# Швидкий вибір зброї клавішами 1, 2, 3
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 and current_weapon_index != 0:
			switch_weapon(0)
			switch_weapon_timer.start()
			return
		elif event.keycode == KEY_2 and current_weapon_index != 1:
			switch_weapon(1)
			switch_weapon_timer.start()
			return
		elif event.keycode == KEY_3 and current_weapon_index != 2:
			switch_weapon(2)
			switch_weapon_timer.start()
			return

	# Скрол мишкою для ПК
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			switch_weapon((current_weapon_index + 1) % weapons_data.size())
			switch_weapon_timer.start()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			switch_weapon((current_weapon_index - 1 + weapons_data.size()) % weapons_data.size())
			switch_weapon_timer.start()

func _on_hitbox_body_entered(body):
	if body.is_in_group("enemies"):
		die()

# Аліас для зворотної сумісності
func _on_area_2d_body_entered(body):
	_on_hitbox_body_entered(body)
