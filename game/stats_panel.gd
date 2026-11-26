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

var last_heal_sec: int = -999
var last_magic_sec: int = -999

func _process(_delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player: return
	
	# Оновлення магії Q (лише коли змінилась секунда або статус)
	var h_sec = int(ceil(player.heal_cooldown)) if player.heal_cooldown > 0 else 0
	if h_sec != last_heal_sec:
		last_heal_sec = h_sec
		if h_sec > 0:
			heal_label.text = "Heal: %ds" % h_sec
			heal_label.modulate = Color(1, 0.4, 0.4)
		else:
			heal_label.text = "Heal: READY"
			heal_label.modulate = Color(0.4, 1, 0.4)

	# Оновлення магії E (лише коли змінилась секунда або статус)
	var m_sec = int(ceil(player.magic_cooldown)) if player.magic_cooldown > 0 else 0
	if m_sec != last_magic_sec:
		last_magic_sec = m_sec
		if m_sec > 0:
			magic_label.text = "Grimoire: %ds" % m_sec
			magic_label.modulate = Color(1, 0.4, 0.4)
		else:
			magic_label.text = "Grimoire: READY"
			magic_label.modulate = Color(0.4, 1, 0.4)

# Оновлення статів лише при зміні тексту
func update_stats(dmg, dmg_time, spd, spd_time):
	var dmg_text = "Damage: x%.1f" % dmg
	if dmg_time > 0:
		dmg_text += " (%.1fs)" % dmg_time
		if damage_label.modulate != Color(1, 1, 0): damage_label.modulate = Color(1, 1, 0)
	else:
		if damage_label.modulate != Color(1, 1, 1): damage_label.modulate = Color(1, 1, 1)
	if damage_label.text != dmg_text:
		damage_label.text = dmg_text
	
	var spd_text = "Speed: %d" % int(spd)
	if spd_time > 0:
		spd_text += " (%.1fs)" % spd_time
		if speed_label.modulate != Color(1, 1, 0): speed_label.modulate = Color(1, 1, 0)
	else:
		if speed_label.modulate != Color(1, 1, 1): speed_label.modulate = Color(1, 1, 1)
	if speed_label.text != spd_text:
		speed_label.text = spd_text

func _on_weapon_changed(weapon_name):
	weapon_label.text = "Weapon: " + weapon_name
