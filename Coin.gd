extends Area2D

func _on_Coin_body_entered(body):
	$"/root/Player".deposit()
	self.queue_free()
