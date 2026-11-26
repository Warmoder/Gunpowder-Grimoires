extends Control

# Масштаб карти (зменшуй або збільшуй, щоб віддалити/наблизити карту)
@export var zoom: float = 0.05 

# Кольори для об'єктів на карті
@export var player_color: Color = Color("00ff00") # Зелений
@export var enemy_color: Color = Color("ff0000")  # Червоний
@export var boss_color: Color = Color("ff00ff")   # Фіолетово-пурпурний (Бос)
@export var chest_color: Color = Color("aaaaaa")  # Сірий (скрині/зілля)
@export var portal_color: Color = Color("00aaff") # Синій

var player: Node2D
var redraw_timer: float = 0.0
const REDRAW_INTERVAL: float = 0.066 # ~15 FPS для мінікарти (величезна економія CPU на мобільних)

func _ready():
	# Цей рядок гарантує, що крапки не вилізуть за межі віконця мінікарти
	clip_contents = true 

func _process(delta):
	if not is_visible_in_tree(): return
	
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player: return
	
	redraw_timer += delta
	if redraw_timer >= REDRAW_INTERVAL:
		redraw_timer = 0.0
		queue_redraw()

func _draw():
	if not player: return
	
	# Знаходимо центр нашого віконця
	var center = size / 2
	var p_pos = player.global_position
	
	# 1. Малюємо Гравця (завжди в центрі віконця)
	draw_rect(Rect2(center - Vector2(4, 4), Vector2(8, 8)), player_color)
	
	# 2. Малюємо Ворогів та Боса
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.is_queued_for_deletion() or enemy.get("is_dead"): continue
		var offset = (enemy.global_position - p_pos) * zoom
		if enemy.is_in_group("boss"):
			draw_rect(Rect2(center + offset - Vector2(5, 5), Vector2(10, 10)), boss_color)
		else:
			draw_rect(Rect2(center + offset - Vector2(3, 3), Vector2(6, 6)), enemy_color)
		
	# 3. Малюємо Портал
	var portals = get_tree().get_nodes_in_group("portal")
	for portal in portals:
		var offset = (portal.global_position - p_pos) * zoom
		draw_rect(Rect2(center + offset - Vector2(4, 4), Vector2(8, 8)), portal_color)
		
	# 4. Малюємо Лут/Зілля
	var loots = get_tree().get_nodes_in_group("loot")
	for loot in loots:
		var offset = (loot.global_position - p_pos) * zoom
		draw_rect(Rect2(center + offset - Vector2(2, 2), Vector2(4, 4)), chest_color)
