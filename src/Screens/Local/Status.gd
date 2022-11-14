extends PanelContainer

onready var username_node = $VBoxContainer/HBoxContainer/Username
onready var content_node = $VBoxContainer/Text
onready var avatar_node = $VBoxContainer/HBoxContainer/ProfilePic
onready var timestamp_node = $VBoxContainer/HBoxContainer/Timestamp

var username: String
var content: String
var timestamp: String

func load_avatar(texture: ImageTexture):
	avatar_node.texture = texture

func _ready():
	username_node.text = username
	timestamp_node.text = timestamp
	content_node.text = content
	pass
