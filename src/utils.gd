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

static func f_remove(filename):
	var dir = Directory.new()
	dir.remove("user://" + filename + ".dat")

static func bad_html_parse(text: String) -> String:
	var e = false
	var i = 0
	while (i < text.length()):
		if (text[i] == "<"):
			e = true
		if (text[i] == ">" && e):
			text.erase(i, 1)
			i -= 1
			e = false
		if (e):
			text.erase(i, 1)
			i -= 1
		i += 1
	text = text.replacen("&#39;", "'")
	return text
#		FOR LOOPS ARE DUMB

static func custom_has_object_array (array: Array, key: String, value) -> bool:
	for i in array:
		if (i[key] == value): 
			return true
	return false
