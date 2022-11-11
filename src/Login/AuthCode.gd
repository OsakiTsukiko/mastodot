extends CenterContainer

onready var error_cont = $Control/Error
onready var input = $Control/Input
onready var btn = $Control/Button

var error_text: String

func load_error(error: String = ""):
	if (error != ""):
		error_text = error
		error_cont.text = error
	else:
		if (error_text != ""):
			error_cont.text = error_text
	return

func _ready():
	load_error()
	return


func _on_button_pressed():
	btn.disabled = true
	var value = input.text
	input.text = ""
	if (value == ""):
		load_error("Field is empty!")
		btn.disabled = false
		return
	var main_scene: Node = get_tree().get_nodes_in_group("main")[0]
	if ( main_scene.has_method("handle_auth_code") ):
			main_scene.handle_auth_code(value)
			queue_free()
	
