extends Node2D

export var terrain_height_min = 10;
export var terrain_height_max = 300;
export var terrain_poly_size = 100;

export var grass_height_min = -10;
export var grass_height_max = 50;
export var grass_poly_size = 3;

export var coin_spawn_chance = 0.5;

const coinScene = preload("res://Coin.tscn")

var terrainNoise: OpenSimplexNoise;
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

	grassNoise = OpenSimplexNoise.new()
	grassNoise.seed = randi()
	grassNoise.octaves = 5
	grassNoise.period = 5.0

	terrain_outer_x = get_viewport().size.x
	terrain_outer_y = get_viewport().size.y * 0.3

func set_origin(pos: int):
	self.pos = pos
	update()

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

		var t = (terrainNoise.get_noise_1d(x) + 1) * 0.5
		var d = terrain_height_min + t * (terrain_height_max - terrain_height_min)

		if x % terrain_poly_size == 0:
			groundPoints.push_back(Vector2(x, h - d))

			if !generatedCoins.has(x):
				generatedCoins[x] = true

				if randf() <= coin_spawn_chance:
					var coin = coinScene.instance()
					coin.position = Vector2(x, h - (d + grass_height_max))
					add_child(coin)

		if x % grass_poly_size == 0:
			grassBottomPoints.push_back(Vector2(x, h - d + 10))
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