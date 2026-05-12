extends Control

# Посилання на старі лейбли
@onready var damage_label = $PanelContainer/VBoxContainer/DamageLabel
@onready var speed_label = $PanelContainer/VBoxContainer/SpeedLabel

# Посилання на НОВІ лейбли (згідно з твоїм скріном)
@onready var weapon_label = $PanelContainer2/VBoxContainer/WeaponLabel
@onready var heal_label = $PanelContainer2/VBoxContainer/HealLabel
@onready var magic_label = $PanelContainer2/VBoxContainer/MagicLabel

var player

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player:
		# Перевіряємо, чи ще не підключено, щоб уникнути подвійного підключення
		if not player.stats_updated.is_connected(update_stats):
			player.stats_updated.connect(update_stats)
			
		if not player.weapon_changed.is_connected(_on_weapon_changed):
			player.weapon_changed.connect(_on_weapon_changed)

func _process(_delta):
	if not player: return
	
	# Оновлення магії Q
	if player.heal_cooldown > 0:
		heal_label.text = "Heal: %ds" % int(player.heal_cooldown)
		heal_label.modulate = Color(1, 0.4, 0.4)
	else:
		heal_label.text = "Heal: READY"
		heal_label.modulate = Color(0.4, 1, 0.4)

	# Оновлення магії E
	if player.magic_cooldown > 0:
		magic_label.text = "Grimoire: %ds" % int(player.magic_cooldown)
		magic_label.modulate = Color(1, 0.4, 0.4)
	else:
		magic_label.text = "Grimoire: READY"
		magic_label.modulate = Color(0.4, 1, 0.4)

# Твоя функція, трохи підправлена під сигнали
func update_stats(dmg, dmg_time, spd, spd_time):
	var dmg_text = "Damage: x%.1f" % dmg
	if dmg_time > 0:
		dmg_text += " (%.1fs)" % dmg_time
		damage_label.modulate = Color(1, 1, 0) # Жовтий бонус
	else:
		damage_label.modulate = Color(1, 1, 1)
	damage_label.text = dmg_text
	
	var spd_text = "Speed: %d" % int(spd)
	if spd_time > 0:
		spd_text += " (%.1fs)" % spd_time
		speed_label.modulate = Color(1, 1, 0)
	else:
		speed_label.modulate = Color(1, 1, 1)
	speed_label.text = spd_text

func _on_weapon_changed(weapon_name):
	weapon_label.text = "Weapon: " + weapon_name
