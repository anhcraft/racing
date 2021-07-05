extends RigidBody2D

signal moving;
signal overturn;

export var car_speed = 200
export var car_boost_cooldown = 1
export var car_boost_speed = 50
export var car_ultra_boost_speed = 200
export var car_early_boost_speed = 200
export var car_rapid_rolling_speed = 100
var total_car_speed = car_speed + car_boost_speed + car_ultra_boost_speed + car_early_boost_speed + car_rapid_rolling_speed

const redSkin = preload("res://car_body.png")
const blueSkin = preload("res://car_body_blue.png")
const pinkSkin = preload("res://car_body_pink.png")

var lastBoostTime = 0
var wheelRotate = 0
var runBeforeBrake = false

func on_car_start():
	$EngineRunningSound.play()
	if ($"/root/User".data.owned_items as Array).has("early_boost"):
		$EarlyBoostTimer.start()

func update_skin():
	var skin = $"/root/User".data.skin
	if skin == "red":
		$Body.texture = redSkin
	elif skin == "blue":
		$Body.texture = blueSkin
	elif skin == "pink":
		$Body.texture = pinkSkin

func boost():
	if $LightBoostTimer.is_stopped():
		$LightBoostTimer.start()

func go():
	if $"/root/Player".stopped:
		return

	var items = $"/root/User".data.owned_items as Array
	var speed = 0
	if self.linear_velocity.length() < total_car_speed:
		speed += car_speed
		if items.has("rapid_rolling"):
			speed += car_rapid_rolling_speed
	
		if !$GoPressSound.playing:
			$GoPressSound.play()

	$EngineRunningSound.volume_db = clamp(self.linear_velocity.length() / total_car_speed, 0, 1) * 5

	if items.has("early_boost") && !$EarlyBoostTimer.is_stopped():
		$EarlyBoostTimer.stop()
		speed += car_early_boost_speed

	var velocity = Vector2(1, 1)

	if !$LightBoostTimer.is_stopped() && $"/root/Player".energy == 100:
		$"/root/Player".update_energy(0)
		$HeavyBoostTimer.start()
	elif OS.get_time().second >= lastBoostTime + car_boost_cooldown:
		lastBoostTime = OS.get_time().second
		speed += car_boost_speed

	if self.linear_velocity.length() < total_car_speed * 5 && !$HeavyBoostTimer.is_stopped():
		speed += car_ultra_boost_speed

	velocity = velocity.normalized() * speed
	self.linear_velocity += velocity

func _process(delta):
	if self.linear_velocity.length() >= 50:
		wheelRotate += self.linear_velocity.angle() / 60
		$FrontWheel.rotate(wheelRotate)
		$BackWheel.rotate(wheelRotate)

	if self.linear_velocity.length() >= total_car_speed:
		runBeforeBrake = true

	if self.linear_velocity.length() < total_car_speed * 0.8:
		$GoPressSound.stop()

	if !$"/root/Player".stopped && $UpRayCast.get_collider() != null:
		$GroundHitSound.play()
		$"/root/Player".stopped = true
		$EngineRunningSound.stop()
		$EarlyBoostTimer.stop()
		emit_signal("overturn")
		return

	if self.linear_velocity.length() >= 5:
		emit_signal("moving")

func _on_Car_body_entered(body):
	if !$GroundHitSound.playing && $DownRayCast.get_collider() != null && self.linear_velocity.y > 200:
		$GroundHitSound.play()
