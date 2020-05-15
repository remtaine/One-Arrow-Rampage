extends KinematicBody2D

var _velocity
var _speed = 1000
var _dir
var _owner
var is_fading = false
var c
var launch_successful = false
var attached_to
var attached_to_wr = null

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
	if attached_to_wr != null and attached_to_wr.get_ref():
		if "_velocity" in attached_to:
			print("I HAVE VELOCITY")
			_velocity = attached_to._velocity
	_velocity = move_and_slide(_velocity)

func setup(dir, pos, rot, owner):
	_dir = dir.normalized()
	position = pos
#	look_at(get_global_mouse_position())
	look_at(rot)		
	_owner = owner
	_velocity = _speed * _dir

func fade_away():
	queue_free()

func _on_Area2D_body_entered(body):
	#change state of player to GRAPPLING_MOVING
	if body.has_method("hit"):
		body.hit()
	_velocity = Vector2.ZERO
	launch_successful = true
	move_timer.start()
	_owner.hook_launch_outcome("success", self)


func _on_LaunchTimer_timeout():
	#TODO end on line dist rather than timeout
	if not launch_successful:
		_owner.hook_launch_outcome("failure", self)

func _on_PlayerMoveTimer_timeout():
	_owner.hook_move_outcome("failure")

func retract():
	fade_away()
#	_dir = Utils.get_dir(_owner, self)
#	if global_position.distance_to(_owner.global_position) < _owner.HOOK_LEEWAY:
#		fade_away()
#	else:
#		_velocity = _speed * _dir
