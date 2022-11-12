extends Control

const instance_selector_scene = preload("res://scenes/Login/InstanceSelector.tscn")
const auth_code_scene = preload("res://scenes/Login/AuthCode.tscn")

const loading_scene = preload("res://scenes/Loading.tscn")
const main_screen_scene = preload("res://scenes/MainScreen.tscn")

onready var scene_cont = $Panel/SceneCont
onready var main_http = $HTTPRequest

var current_main_http_req: String
var instance_address: String
var access_token: String
var client_info: Dictionary = {
	"auth_code": "",
	"client_id": "",
	"client_secret": ""
}

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
	
	current_main_http_req = "check_if_instance_exists"
	main_http.request(instance_address + "api/v1/timelines/public?limit=1")

func handle_auth_code(value: String):
	load_loading_screen()
	client_info["auth_code"] = value
	current_main_http_req = "get_access_token"
	
	var req_body := {
		"client_id": client_info["client_id"],
		"client_secret": client_info["client_secret"],
		"redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
		"grant_type": "authorization_code",
		"code": value,
		"scope": "read write follow push"
	}
	
	main_http.request(
		instance_address + "oauth/token", 
		["Content-Type: application/json"], 
		true, 
		HTTPClient.METHOD_POST, 
		to_json(req_body)
	)

# SIGNALS
func _on_main_http_request_completed(result, response_code, headers, body):
	print("Incoming Request Results")
	
	if (current_main_http_req == "check_if_instance_exists"):
		var json = JSON.parse(body.get_string_from_utf8())
		if (response_code == 200):
			current_main_http_req = "create_application"
			var req_body := {
				"client_name": "mastodot",
				"redirect_uris": "urn:ietf:wg:oauth:2.0:oob",
				"scopes": "read write follow push",
				"website": "https://osakitsukiko.github.io"
			}
			main_http.request(
				instance_address + "api/v1/apps", 
				["Content-Type: application/json"], 
				true, 
				HTTPClient.METHOD_POST, 
				to_json(req_body)
			)
			return
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
			init_instance_selector("Error: (HTTP Code) " + response_code)
			return
	
	if (current_main_http_req == "create_application"):
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
	
	if (current_main_http_req == "get_access_token"):
		var json = parse_json(body.get_string_from_utf8())
		access_token = json.access_token
		Utils.f_write("token", access_token)
		free_loading_screen()
		load_main_screen()
		return
	
	return
