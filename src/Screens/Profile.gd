extends MarginContainer

onready var main_http = $HTTPRequest
onready var banner = $VBoxContainer/Banner
onready var avatar = $VBoxContainer/Banner/MarginContainer/Avatar

var current_main_http_req: String
var data: Dictionary

func _ready():
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
