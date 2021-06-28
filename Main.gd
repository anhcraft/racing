extends Node2D

export var camera_move_speed = 0.05

var width;
var height;
var cameraVelocity = 0;

func _ready():
	randomize()
	width = get_viewport().size.x
	height = get_viewport().size.y

	$Sky.position.x -= width * 0.5
	$Sky.position.y -= height * 0.5

	$Car.position.x = width * 0.5
	$Camera.position.x = width * 0.5

	$Car.position.y = height * 0.25
	$Camera.position.y = height * 0.25

	$"/root/Player".connect("updateBalance", self, "_on_Balance_updated")
	_on_Balance_updated($"/root/Player".balance)

func _on_Car_moving():
	if $Car.position.x > $Camera.position.x + 0.05 * width:
		cameraVelocity = $Car.position.x - $Camera.position.x
		$Terrain.set_origin($Camera.position.x - width * 0.5)
	if $Car.position.x < $Camera.position.x - 0.05 * width:
		cameraVelocity = $Car.position.x - $Camera.position.x
		$Terrain.set_origin($Camera.position.x - width * 0.5)
	if $Car.position.y > $Camera.position.y + 0.1 * height:
		$Camera.position.y += 5
	if $Car.position.y < $Camera.position.y - 0.1 * height:
		$Camera.position.y -= 5

func _process(delta):
	var speed = camera_move_speed * delta * abs(cameraVelocity) * Engine.get_frames_per_second()
	if cameraVelocity > 0:
		$Camera.position.x += speed
		$Sky.position.x += speed
		cameraVelocity = max(cameraVelocity - speed, 0)
	if cameraVelocity < 0:
		$Camera.position.x -= speed
		$Sky.position.x -= speed
		cameraVelocity = min(cameraVelocity + speed, 0)

func _on_Balance_updated(balance):
	$CanvasLayer/BalanceText.text = str(balance) + " "
