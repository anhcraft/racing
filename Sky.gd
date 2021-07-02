extends Node

const cloud_txt = preload("res://cloud.png")
const sky_txt = preload("res://sky.png")
const night_sky_txt = preload("res://night_sky.png")

export var wind_speed = 0.1;
export var cloud_amount = 10;
export var cloud_altitude = 400;
export var cloud_altitude_bonus = 200;
export var cloud_space = 100;
export var cloud_spawn_chance = 0.005;

var pos = 0;

func _ready():
	spawn(0, true)

func set_origin(pos: int):
	self.pos = pos
	
func set_night(night: bool):
	if night:
		$CanvasLayer/Sprite.texture = night_sky_txt
	else:
		$CanvasLayer/Sprite.texture = sky_txt

func spawn(i: int, init: bool):
	var origin = $"/root/Player".position
	if !init:
		origin += get_viewport().size.x
	while i < cloud_amount:
		if randf() <= cloud_spawn_chance:
			var node = Sprite.new()
			add_child(node)
			node.texture = cloud_txt
			node.scale.x = 1 / self.scale.x
			node.scale.y = 1 / self.scale.y
			node.modulate = Color(1, 1, 1)
			node.position.x = origin
			node.position.y = get_viewport().size.y - cloud_altitude - (randi() % cloud_altitude_bonus)
			node.add_to_group("clouds")
		i += 1
		origin += randi() % cloud_space

func _on_CloudTimer_timeout():
	var clouds = get_tree().get_nodes_in_group("clouds")
	var edge = pos - get_viewport().size.x
	var i = 0
	for cloud in clouds:
		if cloud is Sprite:
			cloud.position.x -= wind_speed
			if cloud.position.x * self.scale.x <= edge:
				cloud.queue_free()
			else:
				i += 1
	spawn(i, false)
