extends Node2D

export var camera_move_speed = 0.05

var width;
var height;
var cameraVelocityX = 0;
var cameraVelocityY = 0;

func _ready():
	randomize()

	var ds = $DeathScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.hide()

	width = get_viewport().size.x
	height = get_viewport().size.y

	$Car.position.x = width * 0.5
	cameraVelocityX = $Car.position.x
	$"/root/Player".position = $Car.position.x

	$"/root/Player".connect("updateBalance", self, "_on_Balance_updated")
	$"/root/Player".connect("updateEnergy", self, "_on_Energy_updated")
	$"/root/Player".init()

func _on_Car_moving():
	if abs($Car.position.x - $Camera.position.x) >= 0.05 * width:
		cameraVelocityX = $Car.position.x - $Camera.position.x
		if cameraVelocityX > 0:
			$"/root/Player".boost(abs($Car.position.x - $"/root/Player".position))
		$"/root/Player".position = $Car.position.x
		$Terrain.set_origin($"/root/Player".position)
	if abs($Car.position.y - $Camera.position.y) >= 0.05 * height:
		cameraVelocityY = $Car.position.y - $Camera.position.y

func _on_Car_overturn():
	$"/root/Player".stopped = true
	var ds = $DeathScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.show()

func _process(delta):
	if cameraVelocityX != 0:
		var speed = camera_move_speed * delta * abs(cameraVelocityX) * Engine.get_frames_per_second()
		if cameraVelocityX > 0:
			$Camera.position.x += speed
			cameraVelocityX = max(cameraVelocityX - speed, 0)
		if cameraVelocityX < 0:
			$Camera.position.x -= speed
			cameraVelocityX = min(cameraVelocityX + speed, 0)
	if cameraVelocityY != 0:
		var speed = camera_move_speed * delta * abs(cameraVelocityY) * Engine.get_frames_per_second()
		if cameraVelocityY > 0:
			$Camera.position.y += speed
			cameraVelocityY = max(cameraVelocityY - speed, 0)
		if cameraVelocityY < 0:
			$Camera.position.y -= speed
			cameraVelocityY = min(cameraVelocityY + speed, 0)
	$Sky.handle_move($Camera.position.x, delta)
	
func _on_Balance_updated(balance):
	$HUD/BalanceText.text = str(balance) + " "

func _on_Energy_updated(value):
	$HUD/EnergyBar.value = value

func _on_PlayBtn_button_down():
	var ds = $MainScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.hide()
	$"/root/Player".stopped = false

func _on_ContinueBtn_button_down():
	var ds = $DeathScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.hide()

	$Car.mode = RigidBody2D.MODE_KINEMATIC
	$Car.position.y -= 300
	$"/root/Player".position = $Car.position.x
	$Car.rotation = 0
	yield(get_tree().create_timer(0.1), "timeout")
	$"/root/Player".stopped = false
	$Car.mode = RigidBody2D.MODE_RIGID
