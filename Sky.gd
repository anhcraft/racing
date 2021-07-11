extends Node

const sky_txt = preload("res://sky.png")
const night_sky_txt = preload("res://night_sky.png")

func set_night(night: bool):
	if night:
		$Sprite.texture = night_sky_txt
	else:
		$Sprite.texture = sky_txt
