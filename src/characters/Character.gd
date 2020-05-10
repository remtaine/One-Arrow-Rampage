extends KinematicBody2D

class_name Character

signal state_changed(state)

var state = 0
var prev_state = state
var _transitions = {}
var hp = 100
var max_hp = 100

onready var hp_bar = $HealthBar

func _ready():
	hp_bar.set_value(hp)

func enter_state():
	pass

func hit(damage):
	hp -= damage
	hp_bar.set_value(hp)

func change_state(event):
	var transition = [state, event]
	if not transition in _transitions:
		return
	
	prev_state = state
	state = _transitions[transition]
	enter_state()
	
	emit_signal("state_changed", state)
