extends Area2D

func _on_Coin_body_entered(body):
	var pos = $"/root/Player".position.x;
	var d = 1;
	if pos > 500000:
		d = 7;
	elif pos > 200000:
		d = 4;
	elif pos > 80000:
		d = 2;
	$"/root/Player".deposit(d)
	self.queue_free()
