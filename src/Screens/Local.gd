extends MarginContainer

const status_scene = preload("res://scenes/Screens/Local/Status.tscn")

onready var networking = $Networking
onready var status_cont = $VBoxContainer/Feed/MarginContainer/ScrollContainer/StatusCont

var access_token: String
var instance_address: String

func make_http_req(id: String, url: String, headers: Array, secure, method, req_body: Dictionary, data: Dictionary = {}, node_data: Node = Node.new()):
	var http_req_node: HTTPRequest = HTTPRequest.new()
	http_req_node.use_threads = true
	networking.add_child(http_req_node)
	http_req_node.connect("request_completed", self, "http_req_handler", [http_req_node, id, data, node_data])
	http_req_node.request(
		url, 
		headers, 
		secure, 
		method, 
		to_json(req_body)
	)

func _ready():
	make_http_req(
		"get_local_feed",
		instance_address + "api/v1/timelines/public?local=true&limit=40",
		["Authorization: Bearer " + access_token],
		true,
		HTTPClient.METHOD_GET,
		{}
	)

func http_req_handler(result, response_code, headers, body, req_node, id, data, node_data):
	req_node.queue_free()
	if (id == "get_local_feed"):
		var json = parse_json(body.get_string_from_utf8())
		if (Config.debug_mode):
			Utils.f_write("debug_local_feed", to_json(json))
		for status in json:
			var status_node = status_scene.instance()
			status_node.username = status.account.display_name + "\n@" + status.account.acct
			status_node.content = Utils.bad_html_parse(status.content)
			var time_dict = Time.get_datetime_dict_from_datetime_string(status.created_at, false)
			var local_time_info = OS.get_time_zone_info()
#			I've seen somewhere that this is broken on win ^
#			Might have to look into it
			time_dict.hour += local_time_info.bias / 60
			time_dict.day += time_dict.hour / 24
			time_dict.hour = time_dict.hour % 24
			time_dict.minute += local_time_info.bias % 60
#			I'm not even sure this works tbh :skull:
#			Just made it up rn :
			
			status_node.timestamp += String(time_dict.hour).pad_zeros(2) + ":" + String(time_dict.minute).pad_zeros(2) # + " " + String(time_dict.day) + "/" + String(time_dict.month) + "/" + String(time_dict.year) 
			
			status_cont.add_child(status_node)
			make_http_req(
				"avatar",
				status.account.avatar_static,
				["Authorization: Bearer " + access_token],
				true,
				HTTPClient.METHOD_GET,
				{},
				{"url": status.account.avatar_static},
				status_node
			)
		return
	
	if (id == "avatar"):
		var image = Image.new()
		var image_error 
		if (data.url.get_extension() == "png"):
			image_error = image.load_png_from_buffer(body)
		elif (data.url.get_extension() == "jpg"):
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
		node_data.load_avatar(texture)
		return
