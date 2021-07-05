extends Node2D

export var terrain_update_threshold = 50;
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
		from_range = 50000
	},
	{
		min_height = 0,
		max_height = 800,
		from_range = 100000
	},
	{
		min_height = 0,
		max_height = 1200,
		from_range = 200000
	},
	{
		min_height = 10,
		max_height = 1800,
		from_range = 500000
	}
];
export var terrain_poly_size = 250;

export var grass_height_min = 0;
export var grass_height_max = 30;

export var def_coin_spawn_step = 30;
export(Array, Dictionary) var coin_config = [
	{
		chance = 0.2,
		offset = 0,
		special = false
	},
	{
		chance = 0.05,
		offset = 120,
		special = true
	}
];

const coinScene = preload("res://Coin.tscn")
const specialCoinScene = preload("res://SpecialCoin.tscn")

var terrainNoise: OpenSimplexNoise;
var terrain2Noise: OpenSimplexNoise;
var grassNoise: OpenSimplexNoise;
var pos: int;
var terrain_outer_x: int;
var terrain_outer_y: int;
var current_terrain2_config: int;
var generatedCoins = {};
var coin_spawn_step = def_coin_spawn_step;

func _ready():
	init()

func init():
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

	terrain_outer_x = get_viewport().size.x * 1.2
	terrain_outer_y = get_viewport().size.y * 0.7

	pos = 0
	current_terrain2_config = -1
	generatedCoins = {}

	coin_spawn_step = def_coin_spawn_step
	if ($"/root/User".data.owned_items as Array).has("more_coins"):
		coin_spawn_step /= 2
	
	var coins = get_tree().get_nodes_in_group("coins")
	for coin in coins:
		if coin is Area2D:
			coin.queue_free()

func set_origin(pos: int, force: bool = false):
	if !force && abs(pos - self.pos) < terrain_update_threshold:
		return
	self.pos = pos
	update()

func _on_CoinCleaner_timeout():
	var coins = get_tree().get_nodes_in_group("coins")
	var edge = pos - get_viewport().size.x * 2
	var i = 0
	for coin in coins:
		if coin is Area2D:
			if coin.position.x <= edge:
				generatedCoins.erase(coin.name)
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

func _draw():
	var groundPoints = PoolVector2Array()
	var grassTopPoints = PoolVector2Array()
	var grassBottomPoints = PoolVector2Array()
	var w = get_viewport().size.x
	var m = w + terrain_outer_x
	var h = get_viewport().size.y
	var maxY = -h;
	var last_y = 0

	for n in m:
		var x = n - terrain_outer_x + pos

		if x % terrain_poly_size == 0:
			var d = terrain_height_min + ((terrainNoise.get_noise_1d(x) + 1) * 0.5) * (terrain_height_max - terrain_height_min)
			var t2 = get_terrain2_config(x)
			if t2 != null:
				d -= t2["min_height"] + ((terrain2Noise.get_noise_1d(x) + 1) * 0.5) * (t2["max_height"] - t2["min_height"])
			last_y = h - d
			maxY = max(maxY, last_y)
			groundPoints.push_back(Vector2(x, 0 if x < 0 else h - d))

			grassBottomPoints.push_back(Vector2(x, 0 if x < 0 else h - d))
			var g = (grassNoise.get_noise_1d(x) + 1) * 0.5
			var d0 = grass_height_min + g * (grass_height_max - grass_height_min)
			grassTopPoints.insert(0, Vector2(x, (0 if x < 0 else h - d) + d0))

		if x % coin_spawn_step == 0:
			var name = str(x);
			if !generatedCoins.has(name):
				generatedCoins[name] = true
				for c in coin_config:
					if randf() <= c["chance"]:
						var coin = specialCoinScene.instance() if c["special"] else coinScene.instance()
						coin.name = name;
						coin.position = Vector2(x, last_y - (grass_height_max + c["offset"]))
						add_child(coin)

	groundPoints.push_back(Vector2(pos + w + terrain_outer_x, maxY + terrain_outer_y))
	groundPoints.push_back(Vector2(pos - terrain_outer_x, maxY + terrain_outer_y))
	draw_polygon(groundPoints, PoolColorArray([Color8(153, 110, 11)]))

	var grassPoints = PoolVector2Array(grassTopPoints)
	grassPoints.append_array(grassBottomPoints)
	draw_polygon(grassPoints, PoolColorArray([Color8(90, 173, 93)]))

	$StaticBody2D/Collision.set_polygon(groundPoints)
