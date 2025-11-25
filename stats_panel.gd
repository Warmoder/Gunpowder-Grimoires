extends Control

@onready var damage_label = $PanelContainer/VBoxContainer/DamageLabel
@onready var speed_label = $PanelContainer/VBoxContainer/SpeedLabel

func update_stats(dmg, dmg_time, spd, spd_time):
	# Форматуємо текст
	# %.1f означає "одна цифра після коми"
	
	var dmg_text = "Damage: x%.1f" % dmg
	if dmg_time > 0:
		dmg_text += " (%.1fs)" % dmg_time
	damage_label.text = dmg_text
	
	var spd_text = "Speed: %d" % spd
	if spd_time > 0:
		spd_text += " (%.1fs)" % spd_time
	speed_label.text = spd_text
