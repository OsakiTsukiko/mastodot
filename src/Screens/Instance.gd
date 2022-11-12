extends MarginContainer

const style_01 = preload("res://scenes/Screens/Instance/style_01.tres")

onready var networking = $Networking

onready var banner = $HBoxContainer/Thumbnail/ScrollContainer/VBoxContainer/Banner
onready var title = $HBoxContainer/Thumbnail/ScrollContainer/VBoxContainer/Title
onready var url_label = $HBoxContainer/Thumbnail/ScrollContainer/VBoxContainer/URL
onready var user_count = $HBoxContainer/Thumbnail/ScrollContainer/VBoxContainer/HBoxContainerValues/UserCount
onready var status_count = $HBoxContainer/Thumbnail/ScrollContainer/VBoxContainer/HBoxContainerValues/StatusCount
onready var domain_count = $HBoxContainer/Thumbnail/ScrollContainer/VBoxContainer/HBoxContainerValues/DomainCount
onready var short_description = $HBoxContainer/Thumbnail/ScrollContainer/VBoxContainer/Description
onready var email = $HBoxContainer/Thumbnail/ScrollContainer/VBoxContainer/Email
onready var owner_acc = $HBoxContainer/Thumbnail/ScrollContainer/VBoxContainer/Owner
onready var rules_cont = $HBoxContainer/Info/Panel/ScrollContainer/Board/ScrollContainer/RulesCont

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
	title.text = data.title
#	RIP JAP/CHINESE characters? ^
	url_label.text = data.uri
	user_count.text = "\n" + String(data.stats.user_count) + "\n"
	status_count.text = "\n" + String(data.stats.status_count) + "\n"
	domain_count.text = "\n" + String(data.stats.domain_count) + "\n"
	var short_description_text: String = data.description
	
#	BIGH UGH
#	WHY MUST THEY USE HTML IN APIs...
#	OFC INSTANCE ADMINS ARE GONNA USE HTML IF EVEN
#	THE MAIN DEVS OF MASTODON ARE (MASTODON.SOCIAL - used
#	as example in the api docs... -_-)
	var e = false
	var i = 0
	while (i < short_description_text.length()):
		print(i, " ", short_description_text.length())
		if (short_description_text[i] == "<"):
			e = true
		if (short_description_text[i] == ">" && e):
			short_description_text.erase(i, 1)
			i -= 1
			e = false
		if (e):
			short_description_text.erase(i, 1)
			i -= 1
		i += 1
#		FOR LOOPS ARE DUMB
	short_description.text = "\n" + short_description_text + "\n"
	
	email.text = "\nEmail: " + data.email + "\n"
	owner_acc.text = "\nOwner: " + data.contact_account.username + "\n" + data.contact_account.url + "\n"
	
	var t = false
	for rule in data.rules:
		var rule_text = Label.new()
		rule_text.autowrap = true
		if (t):
			var style: StyleBoxFlat = style_01
			rule_text.add_stylebox_override("normal", load("res://scenes/Screens/Instance/style_01.tres"))
		t = !t
		rule_text.text = "\n    " + rule.text + "\n"
#		Padding is hard... and im lazy ^
		rules_cont.add_child(rule_text)
	
	make_http_req(
		"thumbnail",
		data.thumbnail,
		[],
		true,
		HTTPClient.METHOD_GET,
		{}
	)
	

func http_req_handler(result, response_code, headers, body, req_node, id):
	req_node.queue_free()
	if (id == "thumbnail"):
		var image = Image.new()
		var image_error 
		if (data.thumbnail.get_extension() == "png"):
			image_error = image.load_png_from_buffer(body)
		elif (data.thumbnail.get_extension() == "jpg"):
			image_error = image.load_jpg_from_buffer(body)
		elif (data.thumbnail.get_extension() == "webp"):
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
