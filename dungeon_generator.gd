extends Node

@export var map_width: int = 120
@export var map_height: int = 90
@export var tunnel_count: int = 15
@export var brush_radius: int = 2

@export var floor_layer: TileMapLayer
@export var walls_layer: TileMapLayer
@export var lantern_scene: PackedScene
@export var lantern_chance: float = 0.05 

@export var wall_terrain_set: int = 0
@export var wall_terrain: int = 0
@export var floor_source_id: int = 1
@export var floor_coords: Array[Vector2i] = [Vector2i(0, 0)]

var floor_cells: Array[Vector2i] = []

var current_width: int
var current_height: int
var current_tunnel_count: int
var current_brush_radius: int
var current_wall_mode: int = 0

# --- БАГАТОПОТОКОВІСТЬ ---
var map_thread: Thread
signal generation_finished(floor_cells_result)

func _exit_tree():
	if map_thread and map_thread.is_alive():
		map_thread.wait_to_finish()

func generate_map():
	if floor_coords.is_empty():
		print("ПОМИЛКА: Не додано координати підлоги!")
		return
		
	var level_bonus = GameManager.current_level - 1
	current_width = min(map_width + (level_bonus * 10), 300)
	current_height = min(map_height + (level_bonus * 10), 250)
	current_tunnel_count = min(tunnel_count + (level_bonus * 2), 60)
	current_brush_radius = max(2, brush_radius)
	
	if GameManager.current_difficulty == GameManager.Difficulty.EASY:
		current_brush_radius += 1 
		current_tunnel_count -= 5 
	else:
		current_brush_radius -= 1 
		current_tunnel_count += 5 
		
	floor_layer.clear()
	walls_layer.clear()
	floor_cells.clear()
	
	for child in get_children():
		if child.name.begins_with("Lantern"):
			child.queue_free()
	
	# Зчитуємо налаштування у головному потоці до запуску Thread (thread-safety)
	current_wall_mode = GameManager.settings_data.get("wall_mode", 0)
	
	print("Запуск фонової генерації...")
	# Запускаємо важку математику в іншому потоці
	map_thread = Thread.new()
	map_thread.start(_generate_math_in_thread)

# === ЦЕ ВИКОНУЄТЬСЯ НА ІНШОМУ ЯДРІ ПРОЦЕСОРА ===
func _generate_math_in_thread():
	var local_floor_cells: Array[Vector2i] = []
	var floor_dict: Dictionary = {}
	var current_pos = Vector2i(0, 0)
	var padding = current_brush_radius + 2
	var min_x = -current_width / 2 + padding
	var max_x = current_width / 2 - padding
	var min_y = -current_height / 2 + padding
	var max_y = current_height / 2 - padding
	var brush_radius_sq = current_brush_radius * current_brush_radius
	
	# 1. КОПАЄМО ТУНЕЛІ (Математика)
	for i in range(current_tunnel_count):
		var target_pos = Vector2i(randi_range(min_x, max_x), randi_range(min_y, max_y))
		while current_pos.distance_squared_to(target_pos) > 1:
			# Ріжемо пензлем
			for x in range(-current_brush_radius, current_brush_radius + 1):
				for y in range(-current_brush_radius, current_brush_radius + 1):
					if (x * x + y * y) > brush_radius_sq: continue
					var draw_pos = current_pos + Vector2i(x, y)
					if not floor_dict.has(draw_pos):
						floor_dict[draw_pos] = true
						local_floor_cells.append(draw_pos)
			
			# Рухаємось
			var direction = Vector2(target_pos - current_pos).normalized()
			direction += Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
			var move_step = Vector2i(round(direction.x), round(direction.y))
			if move_step == Vector2i.ZERO:
				move_step = Vector2i(randi() % 3 - 1, randi() % 3 - 1)
			current_pos += move_step
			current_pos.x = clamp(current_pos.x, min_x, max_x)
			current_pos.y = clamp(current_pos.y, min_y, max_y)
			
	# 2. ШУКАЄМО СТІНИ ЗАЛЕЖНО ВІД НАЛАШТУВАНЬ (0 = Monolith, 1 = Fast Perimeter)
	var wall_mode = current_wall_mode
	var wall_cells_to_place: Array[Vector2i] = []
	
	if wall_mode == 1:
		# --- РЕЖИМ: FAST PERIMETER (Оптимізований периметр товщиною 4 блоки) ---
		var perimeter_thickness = 4
		var perimeter_dict: Dictionary = {}
		for f_pos in local_floor_cells:
			for dx in range(-perimeter_thickness, perimeter_thickness + 1):
				for dy in range(-perimeter_thickness, perimeter_thickness + 1):
					var neighbor = f_pos + Vector2i(dx, dy)
					if not floor_dict.has(neighbor) and not perimeter_dict.has(neighbor):
						perimeter_dict[neighbor] = true
						wall_cells_to_place.append(neighbor)
	else:
		# --- РЕЖИМ: MONOLITH (Повний моноліт без дірок) ---
		var start_x = -current_width / 2
		var end_x = current_width / 2
		var start_y = -current_height / 2
		var end_y = current_height / 2
		for x in range(start_x, end_x):
			for y in range(start_y, end_y):
				var pos = Vector2i(x, y)
				if not floor_dict.has(pos):
					wall_cells_to_place.append(pos)
				
	# 3. ШУКАЄМО ЛІХТАРІ (з перевіркою мінімальної відстані для уникнення накладання світла)
	var lantern_positions: Array[Vector2i] = []
	var min_lantern_dist_sq = 14.0 * 14.0 # Мінімум 14 тайлів (~448 пікселів) між ліхтарями
	if lantern_scene:
		for pos in local_floor_cells:
			if pos != Vector2i(0, 0) and randf() < lantern_chance:
				var too_close = false
				for existing in lantern_positions:
					var diff = pos - existing
					if (diff.x * diff.x + diff.y * diff.y) < min_lantern_dist_sq:
						too_close = true
						break
				if not too_close:
					lantern_positions.append(pos)

	# Передаємо результати в головний потік для відмальовки
	call_deferred("_apply_generation_to_scene", local_floor_cells, wall_cells_to_place, lantern_positions)

# === ЦЕ ВИКОНУЄТЬСЯ В ГОЛОВНОМУ ПОТОЦІ ===
func _apply_generation_to_scene(generated_floor, wall_cells, lantern_positions):
	map_thread.wait_to_finish() # Закриваємо потік
	floor_cells = generated_floor
	
	# Малюємо підлогу
	for cell in floor_cells:
		var random_floor = floor_coords.pick_random()
		floor_layer.set_cell(cell, floor_source_id, random_floor)
		
	# Малюємо стіни
	walls_layer.set_cells_terrain_connect(wall_cells, wall_terrain_set, wall_terrain, true)
	
	# Малюємо ліхтарі
	var lantern_counter = 0
	for pos in lantern_positions:
		var lantern = lantern_scene.instantiate()
		lantern.name = "Lantern_" + str(lantern_counter)
		lantern_counter += 1
		lantern.position = floor_layer.map_to_local(pos)
		add_child(lantern)
		
	print("Генерація завершена!")
	emit_signal("generation_finished", floor_cells)

# --- КІМНАТА БОСА ---
func create_boss_room() -> Vector2i:
	var farthest_tile = Vector2i(0, 0)
	var max_dist = 0.0
	for tile in floor_cells:
		var dist = tile.distance_to(Vector2i(0, 0))
		if dist > max_dist:
			max_dist = dist
			farthest_tile = tile
			
	var room_radius = 8
	var room_radius_sq = room_radius * room_radius
	var padding = room_radius + 2
	farthest_tile.x = clamp(farthest_tile.x, -current_width/2 + padding, current_width/2 - padding)
	farthest_tile.y = clamp(farthest_tile.y, -current_height/2 + padding, current_height/2 - padding)
	
	var floor_dict = {}
	for f in floor_cells:
		floor_dict[f] = true
	
	var boss_floor = []
	for x in range(-room_radius, room_radius + 1):
		for y in range(-room_radius, room_radius + 1):
			if (x * x + y * y) > room_radius_sq: continue
			var pos = farthest_tile + Vector2i(x, y)
			walls_layer.set_cell(pos, -1) # Стирання стіни
			var random_floor = floor_coords.pick_random()
			floor_layer.set_cell(pos, floor_source_id, random_floor)
			if not floor_dict.has(pos):
				floor_dict[pos] = true
				floor_cells.append(pos)
				boss_floor.append(pos)
				
	# Оновлюємо стіни навколо нової кімнати боса
	var wall_mode = GameManager.settings_data.get("wall_mode", 0)
	var update_thickness = 4 if wall_mode == 1 else 1
	var walls_to_update: Array[Vector2i] = []
	var walls_to_update_dict: Dictionary = {}
	for f_pos in boss_floor:
		for x in range(-update_thickness, update_thickness + 1):
			for y in range(-update_thickness, update_thickness + 1):
				var check_pos = f_pos + Vector2i(x, y)
				if not floor_dict.has(check_pos) and not walls_to_update_dict.has(check_pos):
					walls_to_update_dict[check_pos] = true
					walls_to_update.append(check_pos)
	walls_layer.set_cells_terrain_connect(walls_to_update, wall_terrain_set, wall_terrain, true)
	
	return farthest_tile
