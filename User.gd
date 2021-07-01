extends Node

var data = {
	balance = 0,
	owned_items = [],
};

func _ready():
	load_game()

func load_game():
	var file = File.new()
	if not file.file_exists("user://user.save"):
		return
	file.open("user://user.save", File.READ)
	while file.get_position() < file.get_len():
		data = parse_json(file.get_line())
	file.close()

func save_game():
	var file = File.new()
	file.open("user://user.save", File.WRITE)
	file.store_line(to_json(data))
	file.close()
