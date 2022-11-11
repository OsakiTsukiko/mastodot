extends HBoxContainer

var tag: String
var value: String

func _ready():
	$Name.text = tag
	$Content.text = value
	return
