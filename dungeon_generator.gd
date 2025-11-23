extends Node

# --- РОЗМІРИ КАРТИ ---
@export var map_width: int = 160
@export var map_height: int = 120

# --- НАЛАШТУВАННЯ ГЕНЕРАЦІЇ ---
@export var tunnel_count: int = 30 
@export var brush_radius: int = 3

# --- ШАРИ ---
@export var floor_layer: TileMapLayer
@export var walls_layer: TileMapLayer

# --- НАЛАШТУВАННЯ ТАЙЛІВ (ВАРІАЦІЇ) ---

# Джерело для СТІН
@export var wall_source_id: int = 3
# Список координат для різних видів стін
@export var wall_coords: Array[Vector2i] = [Vector2i(0, 0)]

# Джерело для ПІДЛОГИ
@export var floor_source_id: int = 1
# Список координат для різних видів підлоги
@export var floor_coords: Array[Vector2i] = [Vector2i(0, 0)]


var floor_cells: Array[Vector2i] = []

func generate_map():
	# Перевірка безпеки: якщо ви забули додати тайли в інспекторі
	if wall_coords.is_empty() or floor_coords.is_empty():
		print("ПОМИЛКА: Не додано координати тайлів в Інспекторі!")
		return []

	print("Починаємо генерацію...")
	floor_layer.clear()
	walls_layer.clear()
	floor_cells.clear()
	
	# 1. Заливаємо стінами
	fill_map_with_walls()
	
	# 2. Копаємо тунелі
	dig_waypoint_tunnels()
	
	print("Генерація завершена.")
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
	
	for x in range(-room_radius, room_radius + 1):
		for y in range(-room_radius, room_radius + 1):
			if Vector2i(x, y).length() > room_radius: continue
			
			var pos = farthest_tile + Vector2i(x, y)
			
			var padding = room_radius + 2
			farthest_tile.x = clamp(farthest_tile.x, -map_width/2 + padding, map_width/2 - padding)
			farthest_tile.y = clamp(farthest_tile.y, -map_height/2 + padding, map_height/2 - padding)
			
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
	var start_x = -map_width / 2
	var end_x = map_width / 2
	var start_y = -map_height / 2
	var end_y = map_height / 2
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var pos = Vector2i(x, y)
			
			# Вибираємо випадкову стіну зі списку
			var random_wall = wall_coords.pick_random()
			walls_layer.set_cell(pos, wall_source_id, random_wall)

func dig_waypoint_tunnels():
	var current_pos = Vector2i(0, 0)
	var padding = brush_radius + 2
	var min_x = -map_width / 2 + padding
	var max_x = map_width / 2 - padding
	var min_y = -map_height / 2 + padding
	var max_y = map_height / 2 - padding
	
	for i in range(tunnel_count):
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
	for x in range(-brush_radius, brush_radius + 1):
		for y in range(-brush_radius, brush_radius + 1):
			if Vector2i(x, y).length() > brush_radius: continue
			var draw_pos = center_pos + Vector2i(x, y)
			
			walls_layer.set_cell(draw_pos, -1)
			
			if not draw_pos in floor_cells:
				# Вибираємо випадкову підлогу зі списку
				var random_floor = floor_coords.pick_random()
				floor_layer.set_cell(draw_pos, floor_source_id, random_floor)
				floor_cells.append(draw_pos)
