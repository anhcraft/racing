extends Node2D

export(Array, Dictionary) var terrain_config = [
	# WARNING: must be ordered by `from_range` from LOWEST to HIGHEST
	{
		min_height = 0,
		max_height = 100,
		from_range = 1000
	},
	{
		min_height = 0,
		max_height = 300,
		from_range = 5000
	},
	{
		min_height = 5,
		max_height = 500,
		from_range = 10000
	},
	{
		min_height = 10,
		max_height = 800,
		from_range = 20000
	},
	{
		min_height = 15,
		max_height = 1200,
		from_range = 50000
	},
	{
		min_height = 20,
		max_height = 1800,
		from_range = 100000
	}
];
export var terrain_poly_size = 250;

export var grass_height_min = 0;
export var grass_height_max = 30;

export var def_coin_spawn_step = 30;
export var coin_spawn_step_1 = 18;
export var coin_spawn_step_2 = 10;
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
export var groundTxtScale = 2;

const coinScene = preload("res://Coin.tscn")
const specialCoinScene = preload("res://SpecialCoin.tscn")
const groundTxt = preload("res://ground.png")

var terrainNoise: OpenSimplexNoise;
var grassNoise: OpenSimplexNoise;
var pos: int;
var terrain_update_threshold: float;
var terrain_outer_x: int;
var terrain_outer_y: int;
var current_terrain_config: int;
var generatedCoins = {};
var coin_spawn_step = def_coin_spawn_step;

func _ready():
	init()

func init():
	terrainNoise = OpenSimplexNoise.new()
	terrainNoise.seed = randi()
	terrainNoise.octaves = 3
	terrainNoise.period = 1000.0
	terrainNoise.persistence = 0.2

	grassNoise = OpenSimplexNoise.new()
	grassNoise.seed = randi()
	grassNoise.octaves = 5
	grassNoise.period = 1.0

	terrain_outer_x = get_viewport().size.x * 2
	terrain_outer_y = get_viewport().size.y * 0.7

	terrain_update_threshold = get_viewport().size.x * 0.5

	pos = 0
	current_terrain_config = -1
	generatedCoins = {}

	coin_spawn_step = def_coin_spawn_step
	if ($"/root/User".data.owned_items as Array).has("more_coins"):
		coin_spawn_step = coin_spawn_step_1
	if ($"/root/User".data.owned_items as Array).has("more_coins2"):
		coin_spawn_step = coin_spawn_step_2

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

func get_terrain_config(x: int):
	# To improve performance, we will cache the current terrain state
	if current_terrain_config + 1 < terrain_config.size():
		if x >= terrain_config[current_terrain_config + 1]["from_range"]:
			current_terrain_config += 1

	if current_terrain_config == -1:
		return null

	# However, in a frame, it is possible to have two states at the same time
	# so we need to manually check for the previous state
	if x < terrain_config[current_terrain_config]["from_range"]:
		return null if current_terrain_config == 0 else terrain_config[current_terrain_config - 1]

	return terrain_config[current_terrain_config]

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
			var d = 0
			var t = get_terrain_config(x)
			if t != null:
				d -= t["min_height"] + ((terrainNoise.get_noise_1d(x) + 1) * 0.5) * (t["max_height"] - t["min_height"])
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
	var groundUV = PoolVector2Array();
	for k in groundPoints:
		groundUV.append(Vector2(
			k.x / groundTxt.get_width() * groundTxtScale, 
			k.y / groundTxt.get_height() * groundTxtScale
		));
	draw_polygon(groundPoints, PoolColorArray(), groundUV, groundTxt)

	var grassPoints = PoolVector2Array(grassTopPoints)
	grassPoints.append_array(grassBottomPoints)
	var grassUV = PoolVector2Array();
	for k in grassPoints:
		grassUV.append(Vector2(
			k.x / groundTxt.get_width() * groundTxtScale, 
			k.y / groundTxt.get_height() * groundTxtScale
		));
	draw_polygon(grassPoints, PoolColorArray([Color(0, 0, 0, 1)]), grassUV)

	$StaticBody2D/Collision.set_polygon(groundPoints)
