extends Node

signal updateBalance

var balance = 0;

func deposit():
	balance += 1
	emit_signal("updateBalance", balance)
