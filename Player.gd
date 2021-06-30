extends Node

export var energy_ratio = 0.05;

signal updateBalance
signal updateEnergy

var balance;
var position = 0;
var energy;
var stopped = false;

func init():
	update_balance(0)
	update_energy(0)

func deposit():
	update_balance(balance + 1)

func update_balance(value: int):
	balance = value
	emit_signal("updateBalance", balance)

func boost(delta: float):
	update_energy(energy + delta * energy_ratio)

func update_energy(value: float):
	energy = clamp(value, 0, 100)
	emit_signal("updateEnergy", energy)
