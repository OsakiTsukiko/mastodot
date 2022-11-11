extends MarginContainer

const profile_scene = preload("res://scenes/Screens/Profile.tscn")
const loading_scene = preload("res://scenes/Loading.tscn")

onready var main_http = $HTTPRequest
onready var profile_tab = $TabContainer/Profile

var current_main_http_req: String
var access_token: String
var instance_address: String

func _ready():
	var loading = loading_scene.instance()
	loading.add_to_group("loading")
	profile_tab.add_child(loading)
	
	current_main_http_req = "verify_credentials"
	main_http.request(
		instance_address + "api/v1/accounts/verify_credentials", 
		["Authorization: Bearer " + access_token],
		true,
		HTTPClient.METHOD_GET
	)
	return

func _on_main_http_request_completed(result, response_code, headers, body):
	if (current_main_http_req == "verify_credentials"):
		var json = parse_json(body.get_string_from_utf8())
		Utils.f_write("user_debug", body.get_string_from_utf8())
		for child in profile_tab.get_children():
			if (child.is_in_group("loading")):
				child.queue_free()
		var profile = profile_scene.instance()
		profile.data = json
		profile.instance_address = instance_address
		profile_tab.add_child(profile)
		return
	return
