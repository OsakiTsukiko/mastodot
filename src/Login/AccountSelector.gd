extends MarginContainer

onready var networking = $Networking
onready var user_cont = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/UserContainer

var users: Array = []

func make_http_req(id: String, url: String, headers: Array, secure, method, req_body: Dictionary, data: Dictionary = {}, data_node: Node = Node.new()):
	var http_req_node: HTTPRequest = HTTPRequest.new()
	http_req_node.use_threads = true
	networking.add_child(http_req_node)
	http_req_node.connect("request_completed", self, "http_req_handler", [http_req_node, id, data, data_node])
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
	
	for i in range(0, users.size()):
		var user = users[i]
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
			{
				"user": user,
				"index": i
			}
		)
	pass

func http_req_handler(result, response_code, headers, body, req_node: Node, id: String, data: Dictionary, data_node: Node):
	req_node.queue_free()
	if (id == "verify_credentials"):
		var json = parse_json(body.get_string_from_utf8())
		if (json.has("error")):
			users.erase(data.user)
			Utils.f_write("users", to_json(users))
			return
		var user_button = Button.new()
		user_button.text = "@" + json.username + "@" + data.user.instance
		user_button.clip_text = true
		user_cont.add_child(user_button)
#		var index: int
#		if (user_cont.get_child_count() < data.index):
#			index = user_cont.get_child_count()
#		else:
#			index = data.index

#		UGH :{
		user_cont.move_child(user_button, data.index)
		user_button.connect("pressed", self, "connect_as_user", [data.user])
		make_http_req(
			"button_avatar",
			json.avatar_static,
			[],
			true,
			HTTPClient.METHOD_GET,
			{},
			{
				"url": json.avatar_static
			},
			user_button
		)
		return
	if (id == "button_avatar"):
		var image = Image.new()
		var image_error 
		if (data.url.get_extension() == "png"):
			image_error = image.load_png_from_buffer(body)
		elif (data.url.get_extension() == "jpg"):
			image_error = image.load_jpg_from_buffer(body)
		elif (data.url.get_extension() == "jpeg"):
			image_error = image.load_jpg_from_buffer(body)
		elif (data.url.get_extension() == "webp"):
			image_error = image.load_webp_from_buffer(body)
		else:
			return
		
		if image_error != OK:
			print("An error occurred while trying to display the image.")
			return
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		data_node.expand_icon = true
		data_node.icon = texture
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
