extends CanvasLayer

# Знаходимо вузли за унікальними іменами (%)
@onready var panel = %PanelContainer
@onready var label = %Label

func _ready():
	# 1. Ховаємо ачівку за межі екрану на старті
	offset.y = -200 
	
	# 2. Перевірка наявності вузлів (щоб гра не вилітала)
	if not panel or not label:
		print("ПОМИЛКА: Не знайдено PanelContainer або Label. Перевір унікальні імена (%) у сцені!")
		return

	# 3. Перевірка GameManager
	if not GameManager:
		print("ПОМИЛКА: GameManager не знайдено! Перевір налаштування Autoload.")
		return
	
	# 4. Підключаємося до сигналу
	# Коли GameManager крикне "achievement_unlocked", запуститься функція show_achievement
	if not GameManager.achievement_unlocked.is_connected(show_achievement):
		GameManager.achievement_unlocked.connect(show_achievement)
		print("Сигнал успішно підключено!")

	# --- ТЕСТ ---
	# Розкоментуй рядок нижче, щоб перевірити анімацію одразу при запуску:
	# show_achievement("Тестова Ачівка!") 

func show_achievement(title: String):
	print("Показуємо ачівку: ", title) # Пишемо в консоль для перевірки
	
	# Встановлюємо текст
	label.text = "Unlocked: " + title
	
	# Створюємо анімацію
	var tween = create_tween()
	
	# 1. Опускаємо вниз (з'являється)
	tween.tween_property(self, "offset:y", 20, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 2. Чекаємо 3 секунди
	tween.tween_interval(3.0)
	
	# 3. Піднімаємо вгору (ховається)
	tween.tween_property(self, "offset:y", -200, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
