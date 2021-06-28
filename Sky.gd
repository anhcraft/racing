extends Node2D

const txt = preload("res://cloud.png")

export var wind_speed = 1;
export var cloud_amount = 10;
export var cloud_altitude = 300;
export var cloud_altitude_bonus = 300;
export var cloud_space = 500;
export var cloud_spawn_chance = 0.001;
export var cloud_color_offset = 0.15;
export var horizon_bound = 100;

func _ready():
	spawn(0, true)

func _process(delta):
	var clouds = get_tree().get_nodes_in_group("clouds")
	
	var i = 0
	for cloud in clouds:
		if cloud is Sprite:
			cloud.position.x -= wind_speed * delta * Engine.get_frames_per_second()
			if cloud.position.x < 0:
				cloud.queue_free()
			else:
				i += 1
	spawn(i, false)

func spawn(i: int, init: bool):
	while i < cloud_amount:
		if randf() <= cloud_spawn_chance:
			var node = Sprite.new()
			node.texture = txt
			node.scale.x = 1 / self.scale.x
			node.scale.y = 1 / self.scale.y
			var c = 1 - rand_range(0, cloud_color_offset)
			node.modulate = Color(c, c, c)
			var origin = 0
			if !init:
				origin = 0.75 * get_viewport().size.x
			node.position.x = origin + horizon_bound + (randi() % cloud_space)
			node.position.y = get_viewport().size.y - cloud_altitude - (randi() % cloud_altitude_bonus)
			node.add_to_group("clouds")
			add_child(node)
		i += 1
