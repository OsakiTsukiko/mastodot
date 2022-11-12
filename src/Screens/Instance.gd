extends MarginContainer

onready var main_http = $HTTPRequest

var current_main_http_req: String
var data: Dictionary
var instance_address: String

func _ready():
	pass

func _on_main_http_request_completed(result, response_code, headers, body):
	pass
