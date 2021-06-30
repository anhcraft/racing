extends Node2D

export var terrain_height_min = 10;
export var terrain_height_max = 300;
export var terrain2_height_min = 200;
export var terrain2_height_max = 1000;
export var terrain_poly_size = 100;

export var grass_height_min = -10;
export var grass_height_max = 50;
export var grass_poly_size = 3;

export var coin_spawn_chance = 0.5;

const coinScene = preload("res://Coin.tscn")

var terrainNoise: OpenSimplexNoise;
var terrain2Noise: OpenSimplexNoise;
var grassNoise: OpenSimplexNoise;
var pos: int;
var terrain_outer_x: int;
var terrain_outer_y: int;

var generatedCoins = {};

func _ready():
	terrainNoise = OpenSimplexNoise.new()
	terrainNoise.seed = randi()
	terrainNoise.octaves = 2
	terrainNoise.period = 500.0
	terrainNoise.persistence = 0.6

	terrain2Noise = OpenSimplexNoise.new()
	terrain2Noise.seed = randi()
	terrain2Noise.octaves = 3
	terrain2Noise.period = 700.0
	terrain2Noise.persistence = 0.2

	grassNoise = OpenSimplexNoise.new()
	grassNoise.seed = randi()
	grassNoise.octaves = 5
	grassNoise.period = 5.0

	terrain_outer_x = get_viewport().size.x
	terrain_outer_y = get_viewport().size.y * 0.3

func set_origin(pos: int):
	self.pos = pos
	update()

func _process(delta):
	var coins = get_tree().get_nodes_in_group("coins")
	var edge = pos - get_viewport().size.x * 0.5
	var i = 0
	for coin in coins:
		if coin is Area2D:
			var x = coin.position.x
			if coin.position.x <= edge:
				coin.queue_free()

func _draw():
	var groundPoints = PoolVector2Array()
	var grassTopPoints = PoolVector2Array()
	var grassBottomPoints = PoolVector2Array()
	var w = get_viewport().size.x
	var m = w + terrain_outer_x * 2
	var h = get_viewport().size.y

	for n in m:
		n -= terrain_outer_x
		var x = n + pos

		var d = terrain_height_min + ((terrainNoise.get_noise_1d(x) + 1) * 0.5) * (terrain_height_max - terrain_height_min)
		d += terrain2_height_min + ((terrain2Noise.get_noise_1d(x) + 1) * 0.5) * (terrain2_height_max - terrain2_height_min)

		if x % terrain_poly_size == 0:
			groundPoints.push_back(Vector2(x, h - d))

			if !generatedCoins.has(x):
				generatedCoins[x] = true

				if randf() <= coin_spawn_chance:
					var coin = coinScene.instance()
					coin.position = Vector2(x, h - (d + grass_height_max))
					add_child(coin)

		if x % grass_poly_size == 0:
			grassBottomPoints.push_back(Vector2(x, h - d + 15))
			var g = (grassNoise.get_noise_1d(x) + 1) * 0.5
			d += grass_height_min + g * (grass_height_max - grass_height_min)
			grassTopPoints.insert(0, Vector2(x, h - d))

	groundPoints.push_back(Vector2(pos + w + terrain_outer_x, h + terrain_outer_y))
	groundPoints.push_back(Vector2(pos - terrain_outer_x, h + terrain_outer_y))
	draw_polygon(groundPoints, PoolColorArray([Color8(153, 110, 11)]))

	var grassPoints = PoolVector2Array(grassTopPoints)
	grassPoints.append_array(grassBottomPoints)
	draw_polygon(grassPoints, PoolColorArray([Color8(90, 173, 93)]))

	$StaticBody2D/Collision.set_polygon(groundPoints)
