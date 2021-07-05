extends Node2D

export var camera_move_speed = 0.05 
export(Dictionary) var skin_icons = {
	"red": Color8(227, 90, 90),
	"blue": Color8(68, 154, 235),
	"pink": Color8(177, 110, 235)
};

var width;
var height;
var cameraVelocityX = 0;
var cameraVelocityY = 0;
var goPressing = false;

func _ready():
	randomize()

	var ds = $DeathScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.hide()
	
	var sc = $Store.get_children()
	for si in sc:
		if si is CanvasItem:
			si.hide()

	$HUD/GoBtn.hide()
	$HUD/BoostBtn.hide()

	width = get_viewport().size.x
	height = get_viewport().size.y

	$Car.position.x = 0
	$HUD/DistanceText.text = str($Car.position.x)
	$Car.position.y -= 300

	$"/root/Player".connect("updateBalance", self, "_on_Balance_updated")
	$"/root/Player".connect("updateEnergy", self, "_on_Energy_updated")
	$"/root/Player".init()
	$MainScreen/Skin.color = skin_icons[$"/root/User".data.skin]
	$Car.update_skin()
	$Sky.set_night($"/root/User".data.night)
	if !$"/root/User".data.night:
		$NightLayer/NightOverlay.hide()

func _on_Car_moving():
	if abs($Car.position.x - $Camera.position.x) >= 0.2 * width:
		cameraVelocityX = $Car.position.x - $Camera.position.x
		if cameraVelocityX > 0 && $Car/HeavyBoostTimer.is_stopped():
			$"/root/Player".boost(abs($Car.position.x - $"/root/Player".position))
		$"/root/Player".position = $Car.position.x
		$Terrain.set_origin($"/root/Player".position)
		$HUD/DistanceText.text = str(int($"/root/Player".position))
	if abs($Car.position.y - $Camera.position.y) >= 0.2 * height:
		cameraVelocityY = $Car.position.y - $Camera.position.y

func _on_Car_overturn():
	var ds = $DeathScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.show()
	$"/root/Player".deathCount += 1
	var max_deaths = 1
	if ($"/root/User".data.owned_items as Array).has("resurrection"):
		max_deaths += 1
	if ($"/root/User".data.owned_items as Array).has("resurrection2"):
		max_deaths += 1
	if $"/root/Player".deathCount >= max_deaths:
		$DeathScreen/ContinueBtn.hide()

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
	$Sky.set_origin($Camera.position.x)

func _on_Balance_updated(balance):
	$HUD/BalanceText.text = str(balance) + " "

func _on_Energy_updated(value):
	$HUD/EnergyBar.value = value

func _on_PlayBtn_button_down():
	var ds = $MainScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.hide()

	$"/root/Player".init()
	$Terrain.init()
	$Car.mode = RigidBody2D.MODE_KINEMATIC
	$Car.rotation = 0
	$Car.position.y = 0
	$Car.position.x = 0
	$"/root/Player".position = $Car.position.x
	$Camera.position.x = $Car.position.x # move back immediately
	$Terrain.set_origin($Car.position.x, true)
	yield(get_tree().create_timer(0.1), "timeout")
	$"/root/Player".stopped = false
	$Car.mode = RigidBody2D.MODE_RIGID
	$Car.on_car_start()
	$HUD/GoBtn.show()
	$HUD/BoostBtn.show()

func _on_ContinueBtn_button_down():
	var ds = $DeathScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.hide()

	$Car.mode = RigidBody2D.MODE_KINEMATIC
	$Car.rotation = 0
	$Car.position.y -= 300
	$"/root/Player".position = $Car.position.x
	yield(get_tree().create_timer(0.1), "timeout")
	$"/root/Player".stopped = false
	$Car.mode = RigidBody2D.MODE_RIGID
	$Car.on_car_start()

func _on_BackBtn_button_down():
	var ds = $DeathScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.hide()
	ds = $MainScreen.get_children()
	for dsc in ds:
		if dsc is CanvasItem:
			dsc.show()
	$"/root/User".data.balance += $"/root/Player".balance
	$"/root/User".save_game()
	$"/root/Player".init()
	$HUD/GoBtn.hide()
	$HUD/BoostBtn.hide()

func _on_StoreBtn_button_down():
	var sc = $Store.get_children()
	for si in sc:
		if si is CanvasItem:
			si.show()
	$Store.init()

func _on_DataSaveTask_timeout():
	$"/root/User".save_game()

func _on_Skin_gui_input(event: InputEvent):
	if event is InputEventMouseButton && event.is_pressed():
		var list = ["red"];
		var items = $"/root/User".data.owned_items as Array;
		if items.has("blue_skin"):
			list.append("blue")
		if items.has("pink_skin"):
			list.append("pink")
		var ind = list.find($"/root/User".data.skin)
		var new_ind = 0 if ind == list.size() - 1 else ind + 1
		if ind != new_ind:
			$"/root/User".data.skin = list[new_ind]
			$"/root/User".save_game()
			$MainScreen/Skin.color = skin_icons[$"/root/User".data.skin]
			$Car.update_skin()

func _on_BoostBtn_button_down():
	$Car.boost()

func _on_GoBtn_button_down():
	goPressing = true

func _on_GoBtn_button_up():
	goPressing = false
	$Car/GoReleaseSound.play()

func _on_MainLoop_timeout():
	$Foreground/FPSLabel.text = str(Engine.get_frames_per_second())
	if goPressing:
		$Car.go()

func _on_SkyButton_button_down():
	if ($"/root/User".data.owned_items as Array).has("night_sky"):
		$"/root/User".data.night = !$"/root/User".data.night
		$"/root/User".save_game()
		$Sky.set_night($"/root/User".data.night)
		if $"/root/User".data.night:
			$NightLayer/NightOverlay.show()
		else:
			$NightLayer/NightOverlay.hide()
