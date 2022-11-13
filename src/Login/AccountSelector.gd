extends MarginContainer

onready var networking = $Networking
onready var user_cont = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/UserContainer

var users: Array = []

func make_http_req(id: String, url: String, headers: Array, secure, method, req_body: Dictionary, data: Dictionary = {}):
	var http_req_node: HTTPRequest = HTTPRequest.new()
	http_req_node.use_threads = true
	networking.add_child(http_req_node)
	http_req_node.connect("request_completed", self, "http_req_handler", [http_req_node, id, data])
	http_req_node.request(
		url, 
		headers, 
		secure, 
		method, 
		to_json(req_body)
	)

func _ready():
	if (Utils.f_read("users") != ""):
		var users_json = Utils.f_read("users")
		var u = parse_json(users_json)
		users = u
	
	for user in users:
		if (!user.has("token") || !user.has("instance")):
			users.erase(user)
			Utils.f_write("users", to_json(users))
			continue
		make_http_req(
			"verify_credentials",
			"https://" + user.instance + "/api/v1/accounts/verify_credentials",
			["Authorization: Bearer " + user.token],
			true,
			HTTPClient.METHOD_GET,
			{},
			user
		)
	pass

func http_req_handler(result, response_code, headers, body, req_node: Node, id: String, data: Dictionary):
	req_node.queue_free()
	if (id == "verify_credentials"):
		var json = parse_json(body.get_string_from_utf8())
		if (json.has("error")):
			users.erase(data)
			Utils.f_write("users", to_json(users))
			return
		var user_button = Button.new()
		user_button.text = "@" + json.username + "@" + data.instance
		user_button.clip_text = true
		user_cont.add_child(user_button)
		user_button.connect("pressed", self, "connect_as_user", [data])
		return


func _on_AddAccount_pressed():
	var main_scene: Node = get_tree().get_nodes_in_group("main")[0]
	if ( main_scene.has_method("init_instance_selector") ):
			main_scene.init_instance_selector()
			queue_free()
	pass

func connect_as_user(data: Dictionary):
	var main_scene: Node = get_tree().get_nodes_in_group("main")[0]
	if ( main_scene.has_method("connect_as_user") ):
			main_scene.connect_as_user(data)
			queue_free()
	pass
