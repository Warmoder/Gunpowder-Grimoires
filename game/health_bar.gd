extends Control

@onready var progress_bar = $TextureProgressBar

func update_health(current, max_val):
	progress_bar.max_value = max_val
	progress_bar.value = current
