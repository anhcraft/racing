extends Node

var data = {
	skin = "red",
	theme = "default",
	balance = 0,
	owned_items = [],
	night = false
};

func _ready():
	load_game()

func load_game():
	var file = File.new()
	if not file.file_exists("user://user.save"):
		return
	file.open("user://user.save", File.READ)
	while file.get_position() < file.get_len():
		var t = parse_json(file.get_line()) as Dictionary
		for k in t.keys():
			data[k] = t.get(k)
	file.close()

func save_game():
	var file = File.new()
	file.open("user://user.save", File.WRITE)
	file.store_line(to_json(data))
	file.close()
