extends MarginContainer

const profile_scene = preload("res://scenes/Screens/Profile.tscn")
const loading_scene = preload("res://scenes/Loading.tscn")

onready var networking = $Networking

onready var profile_tab = $TabContainer/Profile

var access_token: String
var instance_address: String

func make_http_req(id: String, url: String, headers: Array, secure, method, req_body: Dictionary):
	var http_req_node: HTTPRequest = HTTPRequest.new()
	networking.add_child(http_req_node)
	http_req_node.connect("request_completed", self, "http_req_handler", [http_req_node, id])
	http_req_node.request(
		url, 
		headers, 
		secure, 
		method, 
		to_json(req_body)
	)

func _ready():
	make_http_req("guagle", "https://google.com", [], true, HTTPClient.METHOD_GET, {})
	
	var loading = loading_scene.instance()
	loading.add_to_group("loading")
	profile_tab.add_child(loading)
	
	make_http_req(
		"verify_credentials",
		instance_address + "api/v1/accounts/verify_credentials",
		["Authorization: Bearer " + access_token],
		true,
		HTTPClient.METHOD_GET,
		{}
	)
	return

func http_req_handler(result, response_code, headers, body, req_node, id):
	req_node.queue_free()
	if (id == "verify_credentials"):
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
