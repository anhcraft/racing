extends Area2D

func _on_Coin_body_entered(body):
	var pos = $"/root/Player".position.x;
	var d = 1;
	if pos > 500000:
		d = 5;
	elif pos > 200000:
		d = 3;
	elif pos > 80000:
		d = 2;
	$"/root/Player".deposit(d)
	self.queue_free()
