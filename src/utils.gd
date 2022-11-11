extends Node
class_name Utils

static func f_write(filename, content):
	var file = File.new()
	file.open("user://" + filename + ".dat", File.WRITE)
	file.store_string(content)
	file.close()

static func f_read(filename):
	var file = File.new()
	file.open("user://" + filename + ".dat", File.READ)
	var content = file.get_as_text()
	file.close()
	return content
