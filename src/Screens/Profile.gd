extends MarginContainer

const field_scene = preload("res://scenes/Screens/Profile/Field.tscn")

onready var main_http = $HTTPRequest
onready var banner = $VBoxContainer/Banner
onready var avatar = $VBoxContainer/Banner/MarginContainer/Avatar
onready var display_name = $VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/DisplayName
onready var followers_count = $VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/FollowersCount
onready var following_count = $VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/FollowingCount
onready var posts_count = $VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/PostsCount
onready var note = $VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/Note

var current_main_http_req: String
var data: Dictionary
var instance_address: String

func _ready():
	display_name.text = data.display_name + "\n@" + data.username + "@" + instance_address
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
	
	current_main_http_req = "banner"
	main_http.request(data.header_static)
	return


func _on_main_http_request_completed(result, response_code, headers, body):
	
	if ( current_main_http_req == "banner" ):
		var image = Image.new()
		var image_error 
		if ("png" in data.header_static):
			image_error = image.load_png_from_buffer(body)
		elif ("jpg" in data.header_static):
			image_error = image.load_jpg_from_buffer(body)
		elif ("webp" in data.header_static):
			image_error = image.load_webp_from_buffer(body)
		else:
			return
		
		if image_error != OK:
			print("An error occurred while trying to display the image.")
			return
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		banner.texture = texture
		current_main_http_req = "avatar"
		main_http.request(data.avatar_static)
		return
	
	if ( current_main_http_req == "avatar" ):
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
