extends Control

const instance_selector_scene = preload("res://scenes/Login/InstanceSelector.tscn")
const auth_code_scene = preload("res://scenes/Login/AuthCode.tscn")

const loading_scene = preload("res://scenes/Loading.tscn")
const main_screen_scene = preload("res://scenes/MainScreen.tscn")

onready var networking = $Networking
onready var scene_cont = $Panel/SceneCont

var instance_address: String
var access_token: String
var client_info: Dictionary = {
	"auth_code": "",
	"client_id": "",
	"client_secret": ""
}

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

func load_loading_screen():
	var loading_screen = loading_scene.instance()
	loading_screen.add_to_group("loading_screen")
	scene_cont.add_child(loading_screen)

func free_loading_screen():
	get_tree().get_nodes_in_group("loading_screen")[0].queue_free()

func load_main_screen():
	var main_screen = main_screen_scene.instance()
	main_screen.add_to_group("main")
	main_screen.access_token = access_token
	main_screen.instance_address = instance_address
	scene_cont.add_child(main_screen)

func _ready():
	OS.min_window_size = get_viewport().size
	if (Utils.f_read("token") == "" || Utils.f_read("instance_address") == ""):
		init_instance_selector()
	else:
		instance_address = Utils.f_read("instance_address")
		access_token = Utils.f_read("token")
		load_main_screen()
	return

# INITs
func init_instance_selector(error_text: String = ""):
	var instance_selector = instance_selector_scene.instance()
	instance_selector.add_to_group("instance_selector")
	instance_selector.error_text = error_text
	scene_cont.add_child(instance_selector)

# HANDLERS
func handle_instance_selector(value: String):
	load_loading_screen()
	print("Attempting to connect to ", value)
	instance_address = "https://" + value + "/"
	Utils.f_write("instance_address", instance_address)
	
	make_http_req(
		"check_if_instance_exists",
		instance_address + "api/v1/timelines/public?limit=1",
		[],
		true,
		HTTPClient.METHOD_GET,
		{}
	)

func handle_auth_code(value: String):
	load_loading_screen()
	client_info["auth_code"] = value
	
	var req_body := {
		"client_id": client_info["client_id"],
		"client_secret": client_info["client_secret"],
		"redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
		"grant_type": "authorization_code",
		"code": value,
		"scope": "read write follow push"
	}

	make_http_req(
		"get_access_token",
		instance_address + "oauth/token",
		["Content-Type: application/json"],
		true,
		HTTPClient.METHOD_POST,
		req_body
	)

func http_req_handler(result, response_code, headers, body, req_node, id):
	req_node.queue_free()
	if (id == "check_if_instance_exists"):
		var json = JSON.parse(body.get_string_from_utf8())
		if (response_code == 200):
			var req_body := {
				"client_name": "mastodot",
				"redirect_uris": "urn:ietf:wg:oauth:2.0:oob",
				"scopes": "read write follow push",
				"website": "https://osakitsukiko.github.io"
			}
			
			make_http_req(
				"create_application",
				instance_address + "api/v1/apps",
				["Content-Type: application/json"],
				true,
				HTTPClient.METHOD_POST,
				req_body
			)
		elif (response_code == 0):
			free_loading_screen()
			instance_address = ""
			init_instance_selector("No internet connection or incorrect instance address!")
			return
		elif (response_code == 404):
			free_loading_screen()
			instance_address = ""
			init_instance_selector("Outdated or not a Mastodon instance!")
			return
		else:
			free_loading_screen()
			instance_address = ""
			init_instance_selector("Error: (HTTP Code) " + String(response_code))
			return
	
	if (id == "create_application"):
		var json = parse_json(body.get_string_from_utf8())
		if ( response_code == 200 ):
			client_info["client_id"] = json.client_id
			client_info["client_secret"] = json.client_secret
			var oauth_url = instance_address + "oauth/authorize?client_id=" + client_info["client_id"] + "&scope=read+write+follow+push&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code"
			OS.set_clipboard(oauth_url)
			OS.shell_open(oauth_url)
			
			free_loading_screen()
			var auth_code: Node = auth_code_scene.instance()
			auth_code.add_to_group("auth_code")
			auth_code.error_text = "* url copied to clipboard"
			scene_cont.add_child(auth_code)
		return
		
	if (id == "get_access_token"):
		var json = parse_json(body.get_string_from_utf8())
		access_token = json.access_token
		Utils.f_write("token", access_token)
		free_loading_screen()
		load_main_screen()
		return
