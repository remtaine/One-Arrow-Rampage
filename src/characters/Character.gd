extends KinematicBody2D

class_name Character

signal state_changed(state)

var is_alive = true
var state = "idle"
var prev_state = state
var prev_event = 0
var _transitions = {}
var hp = 100.0
var max_hp = 100.0
export var instance_name = "none"

onready var healthUI = $UI/HealthUI
onready var hp_bar = $UI/HealthBar
onready var hurt_animation = $AnimationPlayer/HurtAnimationPlayer

func _ready():
	connect("state_changed",$StateLabel, "_on_Character_state_changed")
	
func enter_state():
	pass

func hit():
	pass

func die():
	is_alive = false
	
func change_state(event):
	var transition = [state, event]
	if not transition in _transitions:
		return
	prev_event = event
	prev_state = state
	state = _transitions[transition]
	enter_state()
	
	emit_signal("state_changed", state)
