extends MarginContainer

const status_scene = preload("res://scenes/Screens/Local/Status.tscn")

onready var networking = $Networking
onready var status_cont = $VBoxContainer/Feed/MarginContainer/ScrollContainer/StatusCont
onready var scroll_cont = $VBoxContainer/Feed/MarginContainer/ScrollContainer
onready var scroll_timer = $ScrollTimer

var access_token: String
var instance_address: String

var feed: Array = []

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
#		if (Config.debug_mode):
#			Utils.f_write("debug_local_feed", to_json(json))
		for status in json:
			if (Utils.custom_has_object_array(feed, "id", status.id)):
				continue
			var status_node = status_scene.instance()
			status_node.username = status.account.display_name + "\n@" + status.account.acct
			status_node.content = Utils.bad_html_parse(status.content)
			status_node.sid = status.id
			var time_dict = Time.get_datetime_dict_from_datetime_string(status.created_at, false)
			var local_time_info = OS.get_time_zone_info()

			time_dict.hour += local_time_info.bias / 60
			time_dict.day += time_dict.hour / 24
			time_dict.hour = time_dict.hour % 24
			time_dict.minute += local_time_info.bias % 60
			
			status_node.timestamp += String(time_dict.hour).pad_zeros(2) + ":" + String(time_dict.minute).pad_zeros(2) + " " + String(time_dict.day).pad_zeros(2) + "." + String(time_dict.month).pad_zeros(2) + "." + String(time_dict.year)
			
			var element = {"id": status.id, "node": status_node, "timestamp": Time.get_unix_time_from_datetime_string(status.created_at)}
			var inserted: bool = false
			for j in range(0, feed.size()):
				if (element.timestamp > feed[j].timestamp):
					feed.insert(j, element)
					status_cont.add_child(status_node)
					status_cont.move_child(status_node, j)
					inserted = true
					break
			if (!inserted):
				feed.push_back(element)
				status_cont.add_child(status_node)
				status_cont.move_child(status_node, feed.size())
			
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
		node_data.load_avatar(texture)
		return


func autoreload():
	make_http_req(
		"get_local_feed",
		instance_address + "api/v1/timelines/public?local=true&limit=40",
		["Authorization: Bearer " + access_token],
		true,
		HTTPClient.METHOD_GET,
		{}
	)

func reload_feed_req():
	var url: String = instance_address + "api/v1/timelines/public?local=true&limit=40"
	if (feed.size() > 0):
		url += "&min_id=" + feed[0].id
	make_http_req(
		"get_local_feed",
		url,
		["Authorization: Bearer " + access_token],
		true,
		HTTPClient.METHOD_GET,
		{}
	)

func _on_Refresh_button_pressed():
	feed.clear()
	for child in status_cont.get_children():
		child.queue_free()
	reload_feed_req()


func _on_Update_button_pressed():
	reload_feed_req()

func _process(delta):
	var scroll_bar = scroll_cont.get_v_scrollbar()
	if (((scroll_bar.max_value - scroll_bar.rect_size.y) - scroll_bar.value) <= 0 && scroll_timer.time_left == 0 && feed.size() != 0):
		scroll_timer.start()
		var url: String = instance_address + "api/v1/timelines/public?local=true&limit=40&max_id=" + feed[feed.size() - 1].id
		make_http_req(
			"get_local_feed",
			url,
			["Authorization: Bearer " + access_token],
			true,
			HTTPClient.METHOD_GET,
			{}
		)
