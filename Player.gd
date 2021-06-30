extends Node

signal updateBalance

var balance = 0;
var position = 0;
var stopped = false;

func deposit():
	balance += 1
	emit_signal("updateBalance", balance)
