extends CanvasLayer

const owned_txt = preload("res://owned_btn.png")
const buy_txt = preload("res://buy_btn.png")

export(Dictionary) var items = {
	rapid_rolling = 20000,
	early_boost = 10000,
	blue_skin = 5000,
	pink_skin = 5000
};

var selectedItem;

func init():
	initItem("rapid_rolling", $ItemList/RapidRolling/Price)
	initItem("early_boost", $ItemList/EarlyBoost/Price)
	initItem("blue_skin", $ItemList/BlueCar/Price)
	initItem("pink_skin", $ItemList/PinkCar/Price)
	$Balance.text = "%d coins" % $"/root/User".data.balance
	$OrderConfirm.hide()
	$PopupDialog.hide()
	selectedItem = null;

func initItem(id: String, item: TextureButton):
	if ($"/root/User".data.owned_items as Array).has(id):
		item.texture_normal = owned_txt
		item.disabled = true
	else:
		item.texture_normal = buy_txt

func _on_Price_button_down(id):
	selectedItem = id
	$OrderConfirm.dialog_text = "This item costs %d coins. Continue?" % items[id]
	$OrderConfirm.show()

func _on_OrderConfirm_confirmed():
	if $"/root/User".data.balance >= items[selectedItem]:
		$"/root/User".data.balance -= items[selectedItem]
		($"/root/User".data.owned_items as Array).append(selectedItem)
		$"/root/User".save_game()
		init()
	else:
		selectedItem = null
		$PopupDialog.dialog_text = "Not enough coins!"
		$PopupDialog.show()

func _on_BackBtn_button_down():
	var sc = get_children()
	for si in sc:
		if si is CanvasItem:
			si.hide()
