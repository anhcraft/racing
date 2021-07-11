extends Node

export var energy_ratio = 0.01;

signal updateBalance
signal updateEnergy

var balance;
var position: Vector2 = Vector2(0, 0);
var energy;
var stopped = false;
var deathCount = 0;

func init():
	stopped = false
	update_balance(0)
	update_energy(0)
	deathCount = 0
	stopped = true

func deposit(delta: int):
	update_balance(balance + delta)

func update_balance(value: int):
	if stopped:
		return
	balance = value
	emit_signal("updateBalance", balance)

func boost(delta: float):
	update_energy(energy + delta * energy_ratio)

func update_energy(value: float):
	if stopped:
		return
	energy = clamp(value, 0, 100)
	emit_signal("updateEnergy", energy)
