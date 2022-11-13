extends PanelContainer

onready var username_node = $VBoxContainer/HBoxContainer/Username
onready var content_node = $VBoxContainer/Text
onready var avatar_node = $VBoxContainer/HBoxContainer/ProfilePic

var username: String
var content: String

func load_avatar(texture: ImageTexture):
	avatar_node.texture = texture

func _ready():
	username_node.text = username
	content_node.text = content
	pass
