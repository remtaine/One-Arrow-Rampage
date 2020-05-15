extends KinematicBody2D

class_name Character

signal state_changed(state)

var state = "idle"
var prev_state = state
var _transitions = {}
var hp = 100.0
var max_hp = 100.0

onready var hp_bar = $UI/HealthBar
onready var hurt_animation = $AnimationPlayer/HurtAnimationPlayer
func _ready():
	connect("state_changed",$StateLabel, "_on_Character_state_changed")
	
func enter_state():
	pass

func hit(damage, special = false):
	hurt_animation.play_hurt(special)
	hp -= damage
	hp_bar.set_value(hp)
	if hp <= 0:
		die()

func die():
	pass
	
func change_state(event):
	var transition = [state, event]
	if not transition in _transitions:
		return
	
	prev_state = state
	state = _transitions[transition]
	enter_state()
	
	emit_signal("state_changed", state)
