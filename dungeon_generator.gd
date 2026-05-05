extends Node

# --- БАЗОВІ РОЗМІРИ КАРТИ (Налаштовуються в Інспекторі) ---
@export var map_width: int = 160
@export var map_height: int = 120

# --- БАЗОВІ НАЛАШТУВАННЯ ГЕНЕРАЦІЇ ---
@export var tunnel_count: int = 30 
@export var brush_radius: int = 3

# --- ШАРИ ---
@export var floor_layer: TileMapLayer
@export var walls_layer: TileMapLayer

# --- ДЕКОРАЦІЇ ---
@export var lantern_scene: PackedScene
@export var lantern_chance: float = 0.05 # 5% шанс появи на крайовій стіні

# --- НАЛАШТУВАННЯ СТІН (TERRAINS) ---
@export var wall_terrain_set: int = 0
@export var wall_terrain: int = 0

# --- НАЛАШТУВАННЯ ПІДЛОГИ ---
@export var floor_source_id: int = 1
@export var floor_coords: Array[Vector2i] = [Vector2i(0, 0)]

var floor_cells: Array[Vector2i] = []

# ДИНАМІЧНІ ЗМІННІ (розраховуються для кожного рівня)
var current_width: int
var current_height: int
var current_tunnel_count: int
var current_brush_radius: int

func generate_map():
	if floor_coords.is_empty():
		print("ПОМИЛКА: Не додано координати підлоги в Інспекторі!")
		return []

	print("Починаємо генерацію...")
	
	# --- 1. РОЗРАХУНОК ДИНАМІЧНОЇ СКЛАДНОСТІ ---
	var level_bonus = GameManager.current_level - 1
	
	current_width = map_width + (level_bonus * 10)
	current_height = map_height + (level_bonus * 10)
	current_tunnel_count = tunnel_count + (level_bonus * 2)
	current_brush_radius = brush_radius
	
	if GameManager.current_difficulty == GameManager.Difficulty.EASY:
		current_brush_radius += 1 
		current_tunnel_count -= 5 
	else:
		current_brush_radius -= 1 
		current_tunnel_count += 5 
		
	current_width = min(current_width, 300)
	current_height = min(current_height, 250)
	current_tunnel_count = min(current_tunnel_count, 60)
	current_brush_radius = max(2, current_brush_radius)
	# ------------------------------------------

	floor_layer.clear()
	walls_layer.clear()
	floor_cells.clear()
	
	# Очищаємо старі ліхтарі з попереднього рівня (якщо вони є)
	for child in get_children():
		if child.name.begins_with("Lantern"):
			child.queue_free()
	
	# 2. СПОЧАТКУ копаємо тунелі
	dig_waypoint_tunnels()
	
	# 3. ПОТІМ малюємо "розумні" стіни навколо підлоги
	build_smart_walls()
	
	# 4. Розставляємо ліхтарі
	spawn_lanterns()
	
	print("Генерація завершена. Радіус: ", current_brush_radius, ", Тунелів: ", current_tunnel_count)
	return floor_cells

# --- ФУНКЦІЯ ДЛЯ КІМНАТИ БОСА ---
func create_boss_room() -> Vector2i:
	var farthest_tile = Vector2i(0, 0)
	var max_dist = 0.0
	
	for tile in floor_cells:
		var dist = tile.distance_to(Vector2i(0, 0))
		if dist > max_dist:
			max_dist = dist
			farthest_tile = tile
			
	var room_radius = 8
	var padding = room_radius + 2
	
	farthest_tile.x = clamp(farthest_tile.x, -current_width/2 + padding, current_width/2 - padding)
	farthest_tile.y = clamp(farthest_tile.y, -current_height/2 + padding, current_height/2 - padding)
	
	for x in range(-room_radius, room_radius + 1):
		for y in range(-room_radius, room_radius + 1):
			if Vector2i(x, y).length() > room_radius: continue
			
			var pos = farthest_tile + Vector2i(x, y)
			
			walls_layer.set_cell(pos, -1)
			
			var random_floor = floor_coords.pick_random()
			floor_layer.set_cell(pos, floor_source_id, random_floor)
			
			if not pos in floor_cells:
				floor_cells.append(pos)
				
	# Оновлюємо стіни навколо кімнати боса
	build_smart_walls()
			
	print("Кімната боса створена в точці: ", farthest_tile)
	return farthest_tile

# --- ДОПОМІЖНІ ФУНКЦІЇ ---

func build_smart_walls():
	var wall_cells_to_place: Array[Vector2i] = []
	
	var start_x = -current_width / 2
	var end_x = current_width / 2
	var start_y = -current_height / 2
	var end_y = current_height / 2
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var pos = Vector2i(x, y)
			if not pos in floor_cells:
				wall_cells_to_place.append(pos)
				
	walls_layer.set_cells_terrain_connect(wall_cells_to_place, wall_terrain_set, wall_terrain, true)

func dig_waypoint_tunnels():
	var current_pos = Vector2i(0, 0)
	var padding = current_brush_radius + 2
	
	var min_x = -current_width / 2 + padding
	var max_x = current_width / 2 - padding
	var min_y = -current_height / 2 + padding
	var max_y = current_height / 2 - padding
	
	for i in range(current_tunnel_count):
		var target_x = randi_range(min_x, max_x)
		var target_y = randi_range(min_y, max_y)
		var target_pos = Vector2i(target_x, target_y)
		
		while current_pos.distance_to(target_pos) > 1:
			carve_brush(current_pos)
			var direction = Vector2(target_pos - current_pos).normalized()
			direction += Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
			var move_step = Vector2i(round(direction.x), round(direction.y))
			if move_step == Vector2i.ZERO:
				move_step = Vector2i(randi() % 3 - 1, randi() % 3 - 1)
			current_pos += move_step
			current_pos.x = clamp(current_pos.x, min_x, max_x)
			current_pos.y = clamp(current_pos.y, min_y, max_y)

func carve_brush(center_pos: Vector2i):
	for x in range(-current_brush_radius, current_brush_radius + 1):
		for y in range(-current_brush_radius, current_brush_radius + 1):
			if Vector2i(x, y).length() > current_brush_radius: continue
			var draw_pos = center_pos + Vector2i(x, y)
			
			walls_layer.set_cell(draw_pos, -1)
			
			if not draw_pos in floor_cells:
				var random_floor = floor_coords.pick_random()
				floor_layer.set_cell(draw_pos, floor_source_id, random_floor)
				floor_cells.append(draw_pos)

func spawn_lanterns():
	if not lantern_scene:
		print("Не додано сцену ліхтаря в Інспектор!")
		return
		
	var lantern_counter = 0
	
	# Тепер йдемо по всіх клітинках ПІДЛОГИ
	for floor_pos in floor_cells:
		
		# Не спавнимо ліхтар прямо під ногами гравця на старті (0, 0)
		if floor_pos == Vector2i(0, 0):
			continue
			
		# Кидаємо кубик на появу ліхтаря
		if randf() < lantern_chance:
			var lantern = lantern_scene.instantiate()
			lantern.name = "Lantern_" + str(lantern_counter)
			lantern_counter += 1
			
			# Використовуємо floor_layer для отримання точних координат
			lantern.position = floor_layer.map_to_local(floor_pos)
			
			# Додаємо на сцену
			add_child(lantern)
