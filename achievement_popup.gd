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

func show_achievement(title):
	label.text = "Unlocked: " + title
	
	sound.play()
	
	var tween = create_tween()
	tween.tween_property(self, "offset:y", 20, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(3.0)
	tween.tween_property(self, "offset:y", -150, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
