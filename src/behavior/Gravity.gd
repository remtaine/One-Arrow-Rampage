extends "res://src/behavior/Behavior.gd"

var gravity = 10

func _physics_process(delta):
	if enabled:
		host._velocity.y += gravity # for gravity
		host._velocity = host.move_and_slide(host._velocity)
