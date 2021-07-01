extends Area2D

func _on_Coin_body_entered(body):
	$"/root/Player".deposit(10)
	self.queue_free()
