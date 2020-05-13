extends KinematicBody2D

var _velocity
var _speed = 1250
var _dir
var _owner
var is_fading = false
var c
var launch_successful = false

onready var line = $Node/Trail
onready var sprite = $Sprite
onready var tween = $Tween
onready var launch_timer = $LaunchTimer
onready var move_timer = $PlayerMoveTimer

func _ready():
	sprite.modulate = _owner.color
	c = modulate
	launch_timer.start()
#	line.add_point(_owner.global_position)
	
func _physics_process(delta):
	#TODO when attached, same velocity as body attached to
	_velocity = move_and_slide(_velocity)
#	line.add_point(_owner.global_position)
#	if is_fading:
#		print("fading!")
#		tween.interpolate_property(self, "visibility/modulate", modulate, Color(c.r, c.g, c.b, 0), 1.0,Tween.TRANS_LINEAR,Tween.EASE_IN)

func setup(dir, pos, rot, owner):
	_dir = dir.normalized()
	position = pos
#	look_at(get_global_mouse_position())
	if owner.is_flipped:
		rotation = rot
#		rotation_degrees += 180
		scale.y = -1
	else:
		rotation = rot
	_owner = owner
	
#	look_at(get_global_mouse_position())
#	rotation_degrees += 180
	_velocity = _speed * _dir
	print("VELOCITY IS NOW", _velocity)
	print("DIR IS NOW", _dir)
	print("POS IS NOW", position)

func fade_away():
	queue_free()

func _on_Area2D_body_entered(body):
	#change state of player to GRAPPLING_MOVING
	if body.has_method("change_color"):
		body.change_color(_owner)
	_velocity = Vector2.ZERO
	launch_successful = true
	move_timer.start()
	_owner.hook_launch_outcome("success", self)
	#change state
	pass # Replace with function body.

func _on_LaunchTimer_timeout():
	#TODO end on line dist rather than timeout
	if not launch_successful:
		_owner.hook_launch_outcome("failure", self)

func _on_PlayerMoveTimer_timeout():
	_owner.hook_move_outcome("failure")
