extends "res://src/characters/Character.gd"

enum STATES {
	IDLE,
	WALK,
	RUN,
	JUMP,
	BUMP,
	FALL,
	RESPAWN
}

enum EVENTS {
	INVALID=-1,
	STOP,
	IDLE,
	WALK,
	RUN,
	JUMP,
	BUMP,
	FALL,
	RESPAWN
}

const SPEED = {
	STATES.WALK: 300,
	STATES.RUN: 450
}

export var color = Color(255,0,0,1)
var _speed = 0
var _velocity = Vector2.ZERO
var _collision_normal = Vector2()
var _last_input_direction = Vector2.ZERO

func _init():
	_transitions = {
		[STATES.IDLE, EVENTS.WALK]: STATES.WALK,
		[STATES.IDLE, EVENTS.RUN]: STATES.RUN,
		[STATES.WALK, EVENTS.STOP]: STATES.IDLE,
		[STATES.WALK, EVENTS.RUN]: STATES.RUN,
		[STATES.RUN, EVENTS.STOP]: STATES.IDLE,
		[STATES.RUN, EVENTS.WALK]: STATES.WALK
	}

func _ready():
	pass
#	modulate = color

func _physics_process(delta):
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("tiles"):
			collider.change_color(self)
			
	var input = get_raw_input(state)
	var event = get_event(input)
	change_state(event)

	match state:
		STATES.WALK, STATES.RUN:
			_velocity.x = _speed * input.direction.x
	
	_velocity.y += 10
	_velocity = move_and_slide(_velocity)

func enter_state():
	match state:
		STATES.IDLE:
			_velocity.x = 0
			self._speed = 0

		STATES.WALK, STATES.RUN:
			_speed = SPEED[state]

static func get_raw_input(state):
	return {
		direction = Vector2(-1,0),
		is_running = false#Input.is_action_pressed("run"),
	}

static func get_input_direction(event = Input):
	return Vector2(
		float(event.is_action_pressed("move_right")) - float(event.is_action_pressed("move_left")),
		float(event.is_action_pressed("move_down")) - float(event.is_action_pressed("move_up"))).normalized()

static func get_event(input):
	"""
	Converts the player's input to events. The state machine
	uses these events to trigger transitions from one state to another.
	"""
	var event = EVENTS.INVALID

	if input.direction == Vector2():
		event = EVENTS.STOP
	elif input.is_running:
		event = EVENTS.RUN
	else:
		event = EVENTS.WALK

	return event
