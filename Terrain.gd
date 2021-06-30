extends Node2D

export var terrain_height_min = 10;
export var terrain_height_max = 300;
export(Array, Dictionary) var terrain2_config = [
	# WARNING: must be ordered by `from_range` from LOWEST to HIGHEST
	{
		min_height = 0,
		max_height = 300,
		from_range = 10000
	},
	{
		min_height = 0,
		max_height = 500,
		from_range = 20000
	},
	{
		min_height = 0,
		max_height = 800,
		from_range = 30000
	},
	{
		min_height = 0,
		max_height = 1200,
		from_range = 40000
	},
	{
		min_height = 500,
		max_height = 2500,
		from_range = 50000
	},
	{
		min_height = 1000,
		max_height = 5000,
		from_range = 100000
	},
	{
		min_height = 4000,
		max_height = 8000,
		from_range = 200000
	},
	{
		min_height = 8000,
		max_height = 12000,
		from_range = 500000
	},
	{
		min_height = 10000,
		max_height = 18000,
		from_range = 1000000
	}
];
export var terrain_poly_size = 100;

export var grass_height_min = 0;
export var grass_height_max = 30;
export var grass_poly_size = 3;

export var coin_spawn_chance = 0.5;

const coinScene = preload("res://Coin.tscn")

var terrainNoise: OpenSimplexNoise;
var terrain2Noise: OpenSimplexNoise;
var grassNoise: OpenSimplexNoise;
var pos: int;
var terrain_outer_x: int;
var terrain_outer_y: int;
var current_terrain2_config: int;
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
	terrain2Noise.period = 1000.0
	terrain2Noise.persistence = 0.2

	grassNoise = OpenSimplexNoise.new()
	grassNoise.seed = randi()
	grassNoise.octaves = 5
	grassNoise.period = 1.0

	terrain_outer_x = get_viewport().size.x
	terrain_outer_y = get_viewport().size.y

	current_terrain2_config = -1

func set_origin(pos: int):
	self.pos = pos
	update()

func _process(delta):
	var coins = get_tree().get_nodes_in_group("coins")
	var edge = pos - get_viewport().size.x * 2
	var i = 0
	for coin in coins:
		if coin is Area2D:
			var x = coin.position.x
			if coin.position.x <= edge:
				coin.queue_free()

func get_terrain2_config(x: int):
	# To improve performance, we will cache the current terrain state
	if current_terrain2_config + 1 < terrain2_config.size():
		if x >= terrain2_config[current_terrain2_config + 1]["from_range"]:
			current_terrain2_config += 1

	if current_terrain2_config == -1:
		return null

	# However, in a frame, it is possible to have two states at the same time
	# so we need to manually check for the previous state
	if x < terrain2_config[current_terrain2_config]["from_range"]:
		return null if current_terrain2_config == 0 else terrain2_config[current_terrain2_config - 1]

	return terrain2_config[current_terrain2_config]

func get_next_terrain2_config(x: int):
	if x < terrain2_config[current_terrain2_config]["from_range"]:
		return terrain2_config[current_terrain2_config]
	elif (current_terrain2_config + 1 < terrain2_config.size()) && x < terrain2_config[current_terrain2_config + 1]["from_range"]:
		return terrain2_config[current_terrain2_config]
	return terrain2_config[min(current_terrain2_config + 1, terrain2_config.size() - 1)]

func _draw():
	var groundPoints = PoolVector2Array()
	var grassLastLayer = PoolVector2Array()
	var grassTopPoints = PoolVector2Array()
	var grassBottomPoints = PoolVector2Array()
	var w = get_viewport().size.x
	var m = w + terrain_outer_x * 2
	var h = get_viewport().size.y
	var maxY = -h;
	var grassLayerBroken = false;

	for n in m:
		var x = n - terrain_outer_x + pos

		var d = terrain_height_min + ((terrainNoise.get_noise_1d(x) + 1) * 0.5) * (terrain_height_max - terrain_height_min)
		var t2 = get_terrain2_config(x)
		if t2 != null:
			d -= t2["min_height"] + ((terrain2Noise.get_noise_1d(x) + 1) * 0.5) * (t2["max_height"] - t2["min_height"])
		maxY = max(maxY, h - d)

		if x % terrain_poly_size == 0:
			groundPoints.push_back(Vector2(x, h - d))

			if !generatedCoins.has(x):
				generatedCoins[x] = true

				if randf() <= coin_spawn_chance:
					var coin = coinScene.instance()
					coin.position = Vector2(x, h - (d + grass_height_max))
					add_child(coin)

		if x % grass_poly_size == 0:
			# seperate grass between regions
			var delta = get_next_terrain2_config(x)["from_range"] - x
			if delta >= 0 && delta < terrain_poly_size:
				grassLayerBroken = true
			# reduce the number of redraws to ONE only by marking BEFORE
			# and then executing when the next terrain state REACHED
			elif grassLayerBroken && delta <= 0:
				grassLayerBroken = false
				grassLastLayer.append_array(grassTopPoints)
				grassLastLayer.append_array(grassBottomPoints)
				grassTopPoints.resize(0)
				grassBottomPoints.resize(0)
			elif !grassLayerBroken:
				grassBottomPoints.push_back(Vector2(x, h - d + 30))
				var g = (grassNoise.get_noise_1d(x) + 1) * 0.5
				d += grass_height_min + g * (grass_height_max - grass_height_min)
				grassTopPoints.insert(0, Vector2(x, h - d))

	groundPoints.push_back(Vector2(pos + w + terrain_outer_x, maxY + terrain_outer_y))
	groundPoints.push_back(Vector2(pos - terrain_outer_x, maxY + terrain_outer_y))
	draw_polygon(groundPoints, PoolColorArray([Color8(153, 110, 11)]))

	draw_polygon(grassLastLayer, PoolColorArray([Color8(90, 173, 93)]))
	var grassPoints = PoolVector2Array(grassTopPoints)
	grassPoints.append_array(grassBottomPoints)
	draw_polygon(grassPoints, PoolColorArray([Color8(90, 173, 93)]))

	$StaticBody2D/Collision.set_polygon(groundPoints)
