extends RigidBody2D

signal moving;
signal overturn;

export var car_speed = 500
export var car_boost_cooldown = 1
export var car_boost_speed = 100
export var car_ultra_boost_speed = 500

var lastBoostTime = 0
var wheelRotate = 0

func _process(delta):
	if self.linear_velocity.length() >= 50:
		wheelRotate += self.linear_velocity.angle() / 60
		$FrontWheel.rotate(wheelRotate)
		$BackWheel.rotate(wheelRotate)

	if !$"/root/Player".stopped:
		if $RayCast2D.get_collider() != null:
			emit_signal("overturn")
			pass

		if self.linear_velocity.length() < car_speed:
			var speed = car_speed
			var velocity = Vector2()

			if Input.is_action_pressed("ui_right") || Input.is_action_pressed("ui_up"):
				velocity.x += 1

			if velocity.length() > 0:
				if Input.is_action_pressed("ui_select") && $"/root/Player".energy == 100:
					$"/root/Player".update_energy(0)
					velocity.y += 1
					speed += car_ultra_boost_speed
				elif OS.get_time().second >= lastBoostTime + car_boost_cooldown:
					lastBoostTime = OS.get_time().second
					speed += car_boost_speed

				velocity = velocity.normalized() * speed * delta * Engine.get_frames_per_second()
				self.linear_velocity += velocity

	if self.linear_velocity.length() >= 5:
		emit_signal("moving")
