extends MarginContainer

const field_scene = preload("res://scenes/Screens/Profile/Field.tscn")

onready var networking = $Networking

onready var banner = $VBoxContainer/Banner
onready var avatar = $VBoxContainer/Banner/MarginContainer/Avatar
onready var display_name = $VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/DisplayName
onready var followers_count = $VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/FollowersCount
onready var following_count = $VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/FollowingCount
onready var posts_count = $VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/PostsCount
onready var note = $VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/Note

var data: Dictionary
var instance_address: String

func make_http_req(id: String, url: String, headers: Array, secure, method, req_body: Dictionary):
	var http_req_node: HTTPRequest = HTTPRequest.new()
	http_req_node.use_threads = true
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
	var uname 
	if (data.has('display_name')): 
		uname = data.display_name 
	else: 
		uname = data.username
	display_name.text = uname + "\n@" + data.username + "@" + instance_address.replace("https://", "").replace("/", "")
	posts_count.text = String(data.statuses_count) + " Posts"
	followers_count.text = String(data.followers_count) + " Followers"
	following_count.text = String(data.following_count) + " Following  "
	note.text = data.source.note
	if (data.source.fields.size() != 0):
		$VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/Padding_04.visible = true
		$VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/Padding_05.visible = true
		$VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/Padding_06.visible = true
		for field_data in data.source.fields:
			var field_instance: Node = field_scene.instance()
			field_instance.tag = field_data.name
			field_instance.value = field_data.value + "  "
			$VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer.add_child(field_instance)
	
	make_http_req(
		"banner",
		data.header_static,
		[],
		true,
		HTTPClient.METHOD_GET,
		{}
	)
	
	make_http_req(
		"avatar",
		data.avatar_static,
		[],
		true,
		HTTPClient.METHOD_GET,
		{}
	)
	
	return

func http_req_handler(result, response_code, headers, body, req_node, id):
	req_node.queue_free()
	if (id == "banner"):
		var image = Image.new()
		var image_error 
		if (data.header_static.get_extension() == "png"):
			image_error = image.load_png_from_buffer(body)
		elif (data.header_static.get_extension() == "jpg"):
			image_error = image.load_jpg_from_buffer(body)
		elif (data.header_static.get_extension() == "webp"):
			image_error = image.load_webp_from_buffer(body)
		else:
			return
		
		if image_error != OK:
			print("An error occurred while trying to display the image.")
			return
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		banner.texture = texture
		return
	
	if (id == "avatar"):
		var image = Image.new()
		var image_error 
		if ("png" in data.avatar_static):
			image_error = image.load_png_from_buffer(body)
		elif ("jpg" in data.avatar_static):
			image_error = image.load_jpg_from_buffer(body)
		elif ("webp" in data.avatar_static):
			image_error = image.load_webp_from_buffer(body)
		else:
			return
		
		if image_error != OK:
			print("An error occurred while trying to display the image.")
			return
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		avatar.texture = texture
		return

func _on_LogOut_pressed():
	var main_screen: Node = get_tree().get_nodes_in_group("main_screen")[0]
	if ( main_screen.has_method("log_out") ):
			main_screen.log_out()


func _on_SwitchAccount_pressed():
	get_tree().reload_current_scene()
