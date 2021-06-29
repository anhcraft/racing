extends Node

const txt = preload("res://cloud.png")

export var wind_speed = 0.1;
export var cloud_amount = 100;
export var cloud_altitude = 400;
export var cloud_altitude_bonus = 200;
export var cloud_space = 100;
export var cloud_spawn_chance = 0.005;
export var cloud_color_offset = 0.15;

func _ready():
	spawn(0, true)

func handle_move(pos: int, delta: float):
	var clouds = get_tree().get_nodes_in_group("clouds")

	var edge = pos - 5 * get_viewport().size.x
	var i = 0
	for cloud in clouds:
		if cloud is Sprite:
			var x = cloud.position.x
			cloud.position.x -= wind_speed * delta * Engine.get_frames_per_second()
			if cloud.position.x <= 0:
				cloud.queue_free()
			else:
				i += 1
	spawn(i, false)

func spawn(i: int, init: bool):
	var origin = $"/root/Player".position
	if !init:
		origin += get_viewport().size.x
	while i < cloud_amount:
		if randf() <= cloud_spawn_chance:
			var node = Sprite.new()
			add_child(node)
			node.name = str(OS.get_time().second) + "#" + str(randi() % 10000)
			node.texture = txt
			node.scale.x = 1 / self.scale.x
			node.scale.y = 1 / self.scale.y
			var c = 1 - rand_range(0, cloud_color_offset)
			node.modulate = Color(c, c, c)
			node.position.x = origin
			node.position.y = get_viewport().size.y - cloud_altitude - (randi() % cloud_altitude_bonus)
			node.add_to_group("clouds")
		i += 1
		origin += randi() % cloud_space
