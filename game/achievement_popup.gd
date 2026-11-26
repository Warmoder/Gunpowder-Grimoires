extends CanvasLayer

@onready var panel = %PanelContainer
@onready var label = %Label
@onready var sound = $AchievementSound

func _ready():
	if not panel or not label:
		print("ERROR: Nodes not found in achievement_popup!")
		return
		
	offset.y = -150 
	if GameManager.has_signal("achievement_unlocked"):
		GameManager.achievement_unlocked.connect(show_achievement)

var _current_tween: Tween = null

func show_achievement(title):
	label.text = "Unlocked: " + title
	
	sound.play()
	
	# Зупиняємо попередній tween, якщо він ще грає (2 ачівки підряд)
	if _current_tween and _current_tween.is_running():
		_current_tween.kill()
	offset.y = -150
	
	_current_tween = create_tween()
	_current_tween.tween_property(self, "offset:y", 20, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_current_tween.tween_interval(3.0)
	_current_tween.tween_property(self, "offset:y", -150, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
