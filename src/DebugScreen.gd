extends CanvasLayer

onready var local_debug = $Control/MarginContainer/Container/LocalDebug

func _process(delta):
	var local_debug_text: String = "Local Feed\n"
	local_debug_text += " - time until feed reload: " + String(GlobalDebug.local.time_until_reload) + "\n"
	local_debug_text += " - statuses in feed: " + String(GlobalDebug.local.loaded_statuses) + "\n"
	
	local_debug.text = local_debug_text
