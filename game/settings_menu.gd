extends Control

@onready var tab_container: TabContainer = $CenterPanel/RootVBox/TabContainer
@onready var back_button: Button = $CenterPanel/RootVBox/BottomBar/BackButton

var is_opened_from_pause = false
var current_res_index = 0

var resolutions = [
	DisplayServer.screen_get_size(), # Native (0)
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(960, 540)
]

# UI references
var fullscreen_check: CheckButton
var vsync_check: CheckButton
var res_label: Label
var max_fps_dropdown: OptionButton
var graphics_dropdown: OptionButton
var brightness_label: Label
var brightness_slider: HSlider
var normal_maps_check: CheckButton
var shadows_check: CheckButton
var lanterns_check: CheckButton
var wall_mode_dropdown: OptionButton

var master_label: Label
var music_label: Label
var sfx_label: Label
var alt_music_check: CheckButton

var show_fps_check: CheckButton
var show_minimap_check: CheckButton
var show_dmg_check: CheckButton
var dmg_scale_label: Label
var dmg_scale_slider: HSlider

# Key rebinding state
var _rebinding_action: String = ""
var _rebinding_button: Button = null
var _keybind_buttons: Dictionary = {}

const ACTION_LABELS = [
	["move_up", "Move Up"],
	["move_down", "Move Down"],
	["move_left", "Move Left"],
	["move_right", "Move Right"],
	["magic_heal", "Heal Spell"],
	["magic_random", "Random Grimoire"],
	["switch_weapon", "Switch Weapon"],
	["toggle_minimap", "Toggle Minimap"],
	["toggle_fullscreen", "Toggle Fullscreen"]
]

func _ready():
	if GameManager.settings_data.has("resolution_index"):
		current_res_index = clampi(int(GameManager.settings_data["resolution_index"]), 0, resolutions.size() - 1)
	
	_build_graphics_tab()
	_build_audio_tab()
	_build_gameplay_tab()
	_build_controls_tab()
	
	back_button.pressed.connect(_on_back_button_pressed)

func _exit_tree():
	InputManager.is_rebinding_key = false

# --- HELPERS ---
func _make_scroll_tab(tab_name: String) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_container.add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	return vbox

func _add_section_header(parent: VBoxContainer, title: String):
	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	parent.add_child(lbl)
	var sep = HSeparator.new()
	parent.add_child(sep)

func _add_toggle_row(parent: VBoxContainer, label_text: String, initial: bool, callback: Callable) -> CheckButton:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 18)
	hbox.add_child(lbl)
	var chk = CheckButton.new()
	chk.set_pressed_no_signal(initial)
	chk.toggled.connect(callback)
	hbox.add_child(chk)
	return chk

func _add_dropdown_row(parent: VBoxContainer, label_text: String, items: Array[String], selected: int, callback: Callable) -> OptionButton:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 18)
	hbox.add_child(lbl)
	var opt = OptionButton.new()
	opt.custom_minimum_size = Vector2(250, 34)
	for it in items:
		opt.add_item(it)
	opt.select(clampi(selected, 0, items.size() - 1))
	opt.item_selected.connect(callback)
	hbox.add_child(opt)
	return opt

func _add_slider_row(parent: VBoxContainer, label_text: String, min_v: float, max_v: float, step_v: float, initial: float, callback: Callable) -> Array:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	parent.add_child(vbox)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(lbl)
	var slider = HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = initial
	slider.value_changed.connect(callback)
	vbox.add_child(slider)
	return [lbl, slider]

# --- TAB 1: GRAPHICS ---
func _build_graphics_tab():
	var vbox = _make_scroll_tab("Graphics")
	_add_section_header(vbox, "Display")
	
	fullscreen_check = _add_toggle_row(vbox, "Exclusive Fullscreen", GameManager.settings_data.get("fullscreen", false), _on_fullscreen_toggled)
	vsync_check = _add_toggle_row(vbox, "V-Sync", GameManager.settings_data.get("vsync", true), _on_vsync_toggled)
	
	# Resolution switcher
	var res_row = HBoxContainer.new()
	vbox.add_child(res_row)
	var res_title = Label.new()
	res_title.text = "Resolution"
	res_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_title.add_theme_font_size_override("font_size", 18)
	res_row.add_child(res_title)
	
	var prev_btn = Button.new()
	prev_btn.text = " < "
	prev_btn.pressed.connect(_on_prev_res_pressed)
	res_row.add_child(prev_btn)
	
	res_label = Label.new()
	res_label.custom_minimum_size = Vector2(185, 0)
	res_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_label.add_theme_font_size_override("font_size", 17)
	res_row.add_child(res_label)
	
	var next_btn = Button.new()
	next_btn.text = " > "
	next_btn.pressed.connect(_on_next_res_pressed)
	res_row.add_child(next_btn)
	update_res_label()
	
	var saved_fps = int(GameManager.settings_data.get("max_fps", 60))
	var fps_idx = 0 if saved_fps == 60 else (1 if saved_fps == 120 else 2)
	max_fps_dropdown = _add_dropdown_row(vbox, "FPS Limit", ["60 FPS", "120 FPS", "Uncapped"], fps_idx, _on_max_fps_selected)
	
	_add_section_header(vbox, "Quality & Lighting")
	var saved_gfx = int(GameManager.settings_data.get("graphics_quality", 1))
	graphics_dropdown = _add_dropdown_row(vbox, "Graphics Preset", ["Low (Potato)", "Medium (Balanced)", "Ultra (2.5D Full)", "Custom"], saved_gfx, _on_graphics_selected)
	
	var saved_b = float(GameManager.settings_data.get("brightness", 1.0))
	var b_pair = _add_slider_row(vbox, "Brightness: %d%%" % roundi(saved_b * 100), 0.5, 2.5, 0.05, saved_b, _on_brightness_changed)
	brightness_label = b_pair[0]
	brightness_slider = b_pair[1]
	
	normal_maps_check = _add_toggle_row(vbox, "2.5D Normal Maps", GameManager.settings_data.get("normal_maps", true), _on_normal_maps_toggled)
	shadows_check = _add_toggle_row(vbox, "Dynamic Shadows", GameManager.settings_data.get("shadows", true), _on_shadows_toggled)
	lanterns_check = _add_toggle_row(vbox, "Wall Lanterns Light", GameManager.settings_data.get("lanterns_light", true), _on_lanterns_toggled)
	
	var saved_wall = int(GameManager.settings_data.get("wall_mode", 0))
	wall_mode_dropdown = _add_dropdown_row(vbox, "Wall Generation", ["Monolith (Full)", "Fast (Perimeter)"], saved_wall, _on_wall_mode_selected)

# --- TAB 2: AUDIO ---
func _build_audio_tab():
	var vbox = _make_scroll_tab("Audio")
	_add_section_header(vbox, "Volume")
	
	var mv = float(GameManager.settings_data.get("master_volume", 1.0))
	master_label = _add_slider_row(vbox, "Master Volume: %d%%" % roundi(mv * 100), 0.0, 1.0, 0.01, mv, _on_master_changed)[0]
	
	var mus = float(GameManager.settings_data.get("music_volume", 1.0))
	music_label = _add_slider_row(vbox, "Music Volume: %d%%" % roundi(mus * 100), 0.0, 1.0, 0.01, mus, _on_music_changed)[0]
	
	var sfx = float(GameManager.settings_data.get("sfx_volume", 1.0))
	sfx_label = _add_slider_row(vbox, "SFX Volume: %d%%" % roundi(sfx * 100), 0.0, 1.0, 0.01, sfx, _on_sfx_changed)[0]
	
	_add_section_header(vbox, "Music Track")
	alt_music_check = _add_toggle_row(vbox, "Alternative Soundtrack", GameManager.settings_data.get("alt_music", false), _on_alt_music_toggled)

# --- TAB 3: GAMEPLAY & HUD ---
func _build_gameplay_tab():
	var vbox = _make_scroll_tab("Gameplay")
	_add_section_header(vbox, "HUD & Visual Feedback")
	
	show_fps_check = _add_toggle_row(vbox, "Show FPS Counter", GameManager.settings_data.get("show_fps", true), _on_show_fps_toggled)
	show_minimap_check = _add_toggle_row(vbox, "Show Minimap", GameManager.settings_data.get("show_minimap", true), _on_show_minimap_toggled)
	show_dmg_check = _add_toggle_row(vbox, "Show Damage Numbers", GameManager.settings_data.get("show_damage_numbers", true), _on_show_dmg_toggled)
	
	var dmg_s = float(GameManager.settings_data.get("damage_numbers_scale", 1.0))
	var d_pair = _add_slider_row(vbox, "Damage Numbers Size: %d%%" % roundi(dmg_s * 100), 0.7, 1.5, 0.05, dmg_s, _on_dmg_scale_changed)
	dmg_scale_label = d_pair[0]
	dmg_scale_slider = d_pair[1]
	dmg_scale_slider.editable = GameManager.settings_data.get("show_damage_numbers", true)

# --- TAB 4: CONTROLS ---
func _build_controls_tab():
	var vbox = _make_scroll_tab("Controls")
	_add_section_header(vbox, "Keybindings (Click to rebind, Esc to cancel)")
	
	_keybind_buttons.clear()
	for pair in ACTION_LABELS:
		var action: String = pair[0]
		var title: String = pair[1]
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		
		var lbl = Label.new()
		lbl.text = title
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 18)
		hbox.add_child(lbl)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(180, 34)
		btn.text = OS.get_keycode_string(GameManager.get_action_keycode(action))
		btn.pressed.connect(_start_rebind.bind(action, btn))
		hbox.add_child(btn)
		_keybind_buttons[action] = btn
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)
	
	var reset_btn = Button.new()
	reset_btn.text = "Reset Controls to Defaults"
	reset_btn.custom_minimum_size = Vector2(0, 38)
	reset_btn.pressed.connect(_on_reset_controls_pressed)
	vbox.add_child(reset_btn)

func _start_rebind(action: String, btn: Button):
	if _rebinding_button and is_instance_valid(_rebinding_button):
		_rebinding_button.text = OS.get_keycode_string(GameManager.get_action_keycode(_rebinding_action))
	_rebinding_action = action
	_rebinding_button = btn
	btn.text = "Press any key..."
	InputManager.is_rebinding_key = true

func _input(event):
	if _rebinding_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE:
			_rebinding_button.text = OS.get_keycode_string(GameManager.get_action_keycode(_rebinding_action))
		else:
			var code = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
			GameManager.rebind_action(_rebinding_action, code)
			_rebinding_button.text = OS.get_keycode_string(code)
		_rebinding_action = ""
		_rebinding_button = null
		InputManager.is_rebinding_key = false

func _on_reset_controls_pressed():
	if _rebinding_action != "":
		_rebinding_action = ""
		_rebinding_button = null
		InputManager.is_rebinding_key = false
	GameManager.reset_keybindings()
	for action in _keybind_buttons.keys():
		_keybind_buttons[action].text = OS.get_keycode_string(GameManager.get_action_keycode(action))

# --- CALLBACKS ---
func _mark_as_custom():
	GameManager.settings_data["graphics_quality"] = 3
	if graphics_dropdown:
		graphics_dropdown.select(3)

func _sync_graphics_controls():
	normal_maps_check.set_pressed_no_signal(GameManager.settings_data.get("normal_maps", true))
	shadows_check.set_pressed_no_signal(GameManager.settings_data.get("shadows", true))
	lanterns_check.set_pressed_no_signal(GameManager.settings_data.get("lanterns_light", true))
	wall_mode_dropdown.select(int(GameManager.settings_data.get("wall_mode", 0)))

func _on_fullscreen_toggled(pressed: bool):
	GameManager.settings_data["fullscreen"] = pressed
	GameManager.apply_settings()
	if not pressed:
		apply_resolution()
	GameManager.save_settings()

func _on_vsync_toggled(pressed: bool):
	GameManager.settings_data["vsync"] = pressed
	GameManager.apply_settings()
	GameManager.save_settings()

func _on_prev_res_pressed():
	current_res_index = (current_res_index - 1 + resolutions.size()) % resolutions.size()
	apply_resolution()

func _on_next_res_pressed():
	current_res_index = (current_res_index + 1) % resolutions.size()
	apply_resolution()

func apply_resolution():
	GameManager.settings_data["resolution_index"] = current_res_index
	update_res_label()
	var target_size = resolutions[current_res_index]
	get_window().content_scale_size = target_size
	if not GameManager.settings_data.get("fullscreen", false) and OS.get_name() != "Android" and OS.get_name() != "iOS":
		DisplayServer.window_set_size(target_size)
		var screen_size = DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size / 2) - (target_size / 2))
	GameManager.save_settings()

func update_res_label():
	if not res_label: return
	var res = resolutions[current_res_index]
	var text = "%d x %d" % [res.x, res.y]
	if current_res_index == 0: text += " (Native)"
	elif res.x * 9 == res.y * 16: text += " (16:9)"
	elif res.x * 3 == res.y * 4: text += " (4:3)"
	res_label.text = text

func _on_max_fps_selected(index: int):
	var fps = 60 if index == 0 else (120 if index == 1 else 0)
	GameManager.settings_data["max_fps"] = fps
	Engine.max_fps = fps
	GameManager.save_settings()

func _on_graphics_selected(index: int):
	if index < 3:
		GameManager.set_preset(index)
		_sync_graphics_controls()
	else:
		GameManager.settings_data["graphics_quality"] = 3
		GameManager.save_settings()

func _on_brightness_changed(value: float):
	GameManager.settings_data["brightness"] = value
	brightness_label.text = "Brightness: %d%%" % roundi(value * 100)
	GameManager.apply_detailed_graphics()
	GameManager.save_settings()

func _on_normal_maps_toggled(pressed: bool):
	_mark_as_custom()
	GameManager.settings_data["normal_maps"] = pressed
	GameManager.apply_detailed_graphics()
	GameManager.save_settings()

func _on_shadows_toggled(pressed: bool):
	_mark_as_custom()
	GameManager.settings_data["shadows"] = pressed
	GameManager.apply_detailed_graphics()
	GameManager.save_settings()

func _on_lanterns_toggled(pressed: bool):
	_mark_as_custom()
	GameManager.settings_data["lanterns_light"] = pressed
	GameManager.apply_detailed_graphics()
	GameManager.save_settings()

func _on_wall_mode_selected(index: int):
	_mark_as_custom()
	GameManager.settings_data["wall_mode"] = index
	GameManager.save_settings()

func _on_master_changed(value: float):
	GameManager.settings_data["master_volume"] = value
	master_label.text = "Master Volume: %d%%" % roundi(value * 100)
	_update_bus_volume("Master", value)
	GameManager.save_settings()

func _on_music_changed(value: float):
	GameManager.settings_data["music_volume"] = value
	music_label.text = "Music Volume: %d%%" % roundi(value * 100)
	_update_bus_volume("Music", value)
	GameManager.save_settings()

func _on_sfx_changed(value: float):
	GameManager.settings_data["sfx_volume"] = value
	sfx_label.text = "SFX Volume: %d%%" % roundi(value * 100)
	_update_bus_volume("SFX", value)
	GameManager.save_settings()

func _update_bus_volume(bus_name: String, linear_value: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))

func _on_alt_music_toggled(pressed: bool):
	GameManager.settings_data["alt_music"] = pressed
	GameManager.save_settings()
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager:
		music_manager.update_track_if_playing()

func _on_show_fps_toggled(pressed: bool):
	GameManager.settings_data["show_fps"] = pressed
	GameManager.update_fps_overlay_visibility()
	GameManager.save_settings()

func _on_show_minimap_toggled(pressed: bool):
	GameManager.settings_data["show_minimap"] = pressed
	GameManager.update_minimap_visibility()
	GameManager.save_settings()

func _on_show_dmg_toggled(pressed: bool):
	GameManager.settings_data["show_damage_numbers"] = pressed
	if dmg_scale_slider:
		dmg_scale_slider.editable = pressed
	GameManager.save_settings()

func _on_dmg_scale_changed(value: float):
	GameManager.settings_data["damage_numbers_scale"] = value
	dmg_scale_label.text = "Damage Numbers Size: %d%%" % roundi(value * 100)
	GameManager.save_settings()

func _on_back_button_pressed():
	InputManager.is_rebinding_key = false
	GameManager.save_settings()
	if is_opened_from_pause:
		queue_free()
	else:
		get_tree().change_scene_to_file("res://main_menu.tscn")
