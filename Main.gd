extends Node2D

export var camera_move_speed = 0.05

var width;
var height;
var cameraVelocity = 0;

func _ready():
	randomize()

	var ds = $DeathScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.hide()

	width = get_viewport().size.x
	height = get_viewport().size.y

	$Car.position.x = width * 0.5
	cameraVelocity = $Car.position.x
	$"/root/Player".position = $Car.position.x

	$"/root/Player".connect("updateBalance", self, "_on_Balance_updated")
	$"/root/Player".connect("updateEnergy", self, "_on_Energy_updated")
	$"/root/Player".init()

func _on_Car_moving():
	if abs($Car.position.x - $Camera.position.x) >= 0.05 * width:
		cameraVelocity = $Car.position.x - $Camera.position.x
		$"/root/Player".boost(abs($Car.position.x - $"/root/Player".position))
		$"/root/Player".position = $Car.position.x
		$Terrain.set_origin($"/root/Player".position)
	if $Car.position.y > $Camera.position.y + 0.1 * height:
		$Camera.position.y += 5
	if $Car.position.y < $Camera.position.y - 0.1 * height:
		$Camera.position.y -= 5

func _on_Car_overturn():
	$"/root/Player".stopped = true
	var ds = $DeathScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.show()

func _process(delta):
	if cameraVelocity == 0:
		return
	var speed = camera_move_speed * delta * abs(cameraVelocity) * Engine.get_frames_per_second()
	if cameraVelocity > 0:
		$Camera.position.x += speed
		cameraVelocity = max(cameraVelocity - speed, 0)
	if cameraVelocity < 0:
		$Camera.position.x -= speed
		cameraVelocity = min(cameraVelocity + speed, 0)
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
	$Car.position.y = 0
	$Car.rotation = 0
	yield(get_tree().create_timer(1.0), "timeout")
	$"/root/Player".stopped = false
	$Car.mode = RigidBody2D.MODE_RIGID
