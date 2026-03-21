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

# --- НАЛАШТУВАННЯ ТАЙЛІВ (ВАРІАЦІЇ) ---
@export var wall_source_id: int = 3
@export var wall_coords: Array[Vector2i] = [Vector2i(0, 0)]
@export var floor_source_id: int = 1
@export var floor_coords: Array[Vector2i] = [Vector2i(0, 0)]

var floor_cells: Array[Vector2i] = []

# ДИНАМІЧНІ ЗМІННІ (розраховуються для кожного рівня)
var current_width: int
var current_height: int
var current_tunnel_count: int
var current_brush_radius: int

func generate_map():
	if wall_coords.is_empty() or floor_coords.is_empty():
		print("ПОМИЛКА: Не додано координати тайлів в Інспекторі!")
		return []

	print("Починаємо генерацію...")
	
	# --- 1. РОЗРАХУНОК ДИНАМІЧНОЇ СКЛАДНОСТІ ---
	var level_bonus = GameManager.current_level - 1
	
	# З кожним рівнем карта росте
	current_width = map_width + (level_bonus * 10)
	current_height = map_height + (level_bonus * 10)
	current_tunnel_count = tunnel_count + (level_bonus * 2)
	current_brush_radius = brush_radius
	
	# Вплив складності
	if GameManager.current_difficulty == GameManager.Difficulty.EASY:
		current_brush_radius += 1 # Ширші коридори на Ізі
		current_tunnel_count -= 5 # Менш заплутано
	else:
		current_brush_radius -= 1 # Вужчі коридори на Харді
		current_tunnel_count += 5 # Більше розвилок
		
	# Обмеження, щоб генератор не зійшов з розуму на 50-му рівні або не зробив тунель нульовим
	current_width = min(current_width, 300)
	current_height = min(current_height, 250)
	current_tunnel_count = min(current_tunnel_count, 60)
	current_brush_radius = max(2, current_brush_radius) # Мінімум 2 тайли радіусу
	# ------------------------------------------

	floor_layer.clear()
	walls_layer.clear()
	floor_cells.clear()
	
	# 2. Заливаємо стінами
	fill_map_with_walls()
	
	# 3. Копаємо тунелі
	dig_waypoint_tunnels()
	
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
	
	# ВИПРАВЛЕННЯ: Обмежуємо центр кімнати ДО того, як малювати її
	farthest_tile.x = clamp(farthest_tile.x, -current_width/2 + padding, current_width/2 - padding)
	farthest_tile.y = clamp(farthest_tile.y, -current_height/2 + padding, current_height/2 - padding)
	
	for x in range(-room_radius, room_radius + 1):
		for y in range(-room_radius, room_radius + 1):
			if Vector2i(x, y).length() > room_radius: continue
			
			var pos = farthest_tile + Vector2i(x, y)
			
			# Прибираємо стіни
			walls_layer.set_cell(pos, -1)
			
			# Вибираємо випадкову підлогу
			var random_floor = floor_coords.pick_random()
			floor_layer.set_cell(pos, floor_source_id, random_floor)
			
			if not pos in floor_cells:
				floor_cells.append(pos)
				
	print("Кімната боса створена в точці: ", farthest_tile)
	return farthest_tile

# --- ДОПОМІЖНІ ФУНКЦІЇ ---

func fill_map_with_walls():
	# Використовуємо динамічні змінні (current_width замість map_width)
	var start_x = -current_width / 2
	var end_x = current_width / 2
	var start_y = -current_height / 2
	var end_y = current_height / 2
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var pos = Vector2i(x, y)
			var random_wall = wall_coords.pick_random()
			walls_layer.set_cell(pos, wall_source_id, random_wall)

func dig_waypoint_tunnels():
	var current_pos = Vector2i(0, 0)
	var padding = current_brush_radius + 2
	
	# Використовуємо динамічні змінні
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
	# Використовуємо динамічний радіус
	for x in range(-current_brush_radius, current_brush_radius + 1):
		for y in range(-current_brush_radius, current_brush_radius + 1):
			if Vector2i(x, y).length() > current_brush_radius: continue
			var draw_pos = center_pos + Vector2i(x, y)
			
			walls_layer.set_cell(draw_pos, -1)
			
			if not draw_pos in floor_cells:
				var random_floor = floor_coords.pick_random()
				floor_layer.set_cell(draw_pos, floor_source_id, random_floor)
				floor_cells.append(draw_pos)
