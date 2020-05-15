extends "res://src/characters/Character.gd"

var STATES = {
	IDLE = "idle",
	WALK = "player walk",
	JUMP = "player jump",
	FALL = "player fall",
	GRAPPLE_LAUNCH_AIR = "player launch air",
	GRAPPLE_LAUNCH_GROUND = "player launch ground",
	GRAPPLE_MOVE  = "player grapple move",
	FLY = "player fly",
	ATTACK_GROUND = "player attack ground",
	ATTACK_AIR = "player attack air",
	ROLL  = "player roll",
}

var EVENTS = {
	INVALID= "player event invalid",
	STOP = "player event stop",
	WALK = "player event walk",
	JUMP = "player event jump",
	ATTACK = "player event attack",
	FALL = "player event fall",
	GRAPPLE_LAUNCH  = "player event grapple launch",
	GRAPPLE_SUCCESS = "player event grapple success",
	GRAPPLE_FAIL  = "player event grapple fail",
	GRAPPLE_DONE = "player event grapply done",
	ROLL = "player event roll",
	LAND = "player event land"
}

enum WEAPON {
	SWORD,
	BOW
}

const DAMAGE =  10.0

const SPEED = 20
const GRAPPLE_SPEED = 700
const JUMP_HEIGHT = -450
const SPEED_LIMIT = Vector2(400, 450)

const FRICTION = 20
const AIR_FRICTION = 2
const TURN_STRENGTH = 1.0
const AIR_CONTROL = 0.5
const GRAVITY = 12
const JUMP_DEFICIENCY = 1

onready var camera = $Camera2D
onready var sprite = $AnimatedSprite #shuld be #Sprite
onready var animation = $AnimationPlayer

const HOOK_LEEWAY = 50
const HOOK_VELOCITY_DAMPENING = 0.7
onready var pivot_pos = $CenterPivot
onready var g_hook_pos = $CenterPivot/ProjectileLaunchPosition1
onready var g_hook_resource = preload("res://src/weapons/GrapplingHook.tscn")

var current_scale = 1
var can_coyote_jump = false
onready var coyote_timer = $GameFeel/CoyoteGroundTimer
onready var jump_buffer_timer = $GameFeel/JumpBufferTimer

export var color = Color(255,0,0,1)

export var is_invulnerable = false
var enemies_damaged = []

var _speed = 0
var _velocity = Vector2.ZERO
var _prev_velocity = Vector2.ZERO #declaration
var _prev_dir = Vector2.ZERO
var _dir = Vector2.ZERO

var current_weapon = WEAPON.SWORD
var _collision_normal = Vector2()
var _last_input_direction = Vector2.ZERO

var can
var current_hook
var current_hook_wr
#var is_climbing = false #TODO dont actually need this, use state instead
var is_running = false
var is_holding_jump = false

var is_flipped = false

func _init():	
	Global.player = self
	_transitions = {
		[STATES.IDLE, EVENTS.WALK]:STATES.WALK,
		[STATES.IDLE, EVENTS.JUMP]:STATES.JUMP,
		[STATES.IDLE, EVENTS.ATTACK]:STATES.ATTACK_GROUND,
		[STATES.IDLE, EVENTS.FALL]:STATES.FALL,
		[STATES.IDLE, EVENTS.GRAPPLE_LAUNCH]:STATES.GRAPPLE_LAUNCH_GROUND,
		
		[STATES.WALK, EVENTS.STOP]:STATES.IDLE,
		[STATES.WALK, EVENTS.JUMP]:STATES.JUMP,
		[STATES.WALK, EVENTS.ATTACK]:STATES.ATTACK_GROUND,
		[STATES.WALK, EVENTS.FALL]:STATES.FALL,
		[STATES.WALK, EVENTS.GRAPPLE_LAUNCH]:STATES.GRAPPLE_LAUNCH_GROUND,
		
		[STATES.JUMP, EVENTS.GRAPPLE_LAUNCH]:STATES.GRAPPLE_LAUNCH_AIR,
		[STATES.JUMP, EVENTS.ATTACK]:STATES.ATTACK_AIR,
		[STATES.JUMP, EVENTS.FALL]:STATES.FALL,

		[STATES.FLY, EVENTS.GRAPPLE_LAUNCH]:STATES.GRAPPLE_LAUNCH_AIR,
		[STATES.FLY, EVENTS.ATTACK]:STATES.ATTACK_AIR,
		[STATES.FLY, EVENTS.JUMP]:STATES.JUMP,
		[STATES.FLY, EVENTS.FALL]:STATES.FALL,
		[STATES.FLY, EVENTS.LAND]:STATES.IDLE,
		
		[STATES.FALL, EVENTS.LAND]:STATES.IDLE, #heading to idle # NO NEED FOR LAND JUST USE DIFF ANIMATION at set_state
		[STATES.FALL, EVENTS.GRAPPLE_LAUNCH]:STATES.GRAPPLE_LAUNCH_AIR,
		[STATES.FALL, EVENTS.ATTACK]:STATES.ATTACK_AIR,
		
		[STATES.GRAPPLE_LAUNCH_AIR, EVENTS.GRAPPLE_SUCCESS]:STATES.GRAPPLE_MOVE,
		[STATES.GRAPPLE_LAUNCH_AIR, EVENTS.GRAPPLE_FAIL]:STATES.FALL,
		
		[STATES.GRAPPLE_LAUNCH_GROUND, EVENTS.GRAPPLE_SUCCESS]:STATES.GRAPPLE_MOVE,
		[STATES.GRAPPLE_LAUNCH_GROUND, EVENTS.GRAPPLE_FAIL]:STATES.IDLE,
		
		[STATES.GRAPPLE_MOVE, EVENTS.GRAPPLE_DONE]:STATES.FLY,
		
		[STATES.ATTACK_GROUND, EVENTS.STOP]:STATES.IDLE,
		
		[STATES.ATTACK_AIR, EVENTS.JUMP]:STATES.JUMP,
		[STATES.ATTACK_AIR, EVENTS.FALL]:STATES.FALL,
		[STATES.ATTACK_AIR, EVENTS.STOP]:STATES.IDLE,
		
		[STATES.ROLL, EVENTS.ROLL]:STATES.IDLE,
	}

func _ready():
	current_scale = sprite.scale
	hp_bar.set_value(hp)

func _physics_process(delta):
	if global_position.y > 700:
		die()
	var input = get_raw_input(state)
	var event = get_event(input)
	change_state(event)

	_dir = input.direction
	
	
	match state:
		STATES.IDLE, STATES.GRAPPLE_LAUNCH_GROUND, STATES.ATTACK_GROUND:
			add_friction()
		STATES.WALK:
			if input.direction.x * _velocity.x < 0:
				_velocity.x += SPEED * _dir.x * TURN_STRENGTH
			else:
				_velocity.x += SPEED * _dir.x
			continue
		STATES.JUMP, STATES.GRAPPLE_LAUNCH_AIR:
#			var temp = 
			if input.direction.x != 0:
				if input.direction.x * _velocity.x < 0:
					_velocity.x += SPEED * _dir.x * AIR_CONTROL
				else:
					pass
					_velocity.x += SPEED * _dir.x * AIR_CONTROL * 0.25
			else:
				add_friction(AIR_FRICTION)
			continue #TODO add air control 
		STATES.JUMP:
			if not input.is_jumping: #whil
				is_holding_jump = false
			if not is_holding_jump:
				_velocity.y += GRAVITY * JUMP_DEFICIENCY * 1.2
			continue
		STATES.JUMP, STATES.GRAPPLE_LAUNCH_AIR, STATES.ATTACK_AIR, STATES.FLY:	
			if is_on_floor():
				change_state(EVENTS.LAND)
#				animation.play("idle")
		STATES.FALL:
#			if not (can_coyote_jump and not is_on_floor()):
			_velocity.y += GRAVITY * JUMP_DEFICIENCY * 1.7
			if is_on_floor():
				change_state(EVENTS.LAND)
#		STATES.GRAPPLE_LAUNCH_AIR:
#		STATES.GRAPPLE_LAUNCH_GROUND:
		STATES.GRAPPLE_MOVE:
			_dir = Utils.get_dir(current_hook, self)
			if current_hook.global_position.distance_to(global_position) < HOOK_LEEWAY:
				change_state(EVENTS.GRAPPLE_DONE)
			else:
				_velocity = GRAPPLE_SPEED * _dir
#		STATES.ATTACK_GROUND:
#		STATES.ATTACK_AIR:
#		STATES.ROLL:

	match state: # for velocity.y
		STATES.GRAPPLE_MOVE:
			pass
#		STATES.WALK, STATES.IDLE, STATES.ATTACK_GROUND:
#			if is_on_floor():
#				_velocity.y += GRAVITY
#			elif not can_coyote_jump:
#				_velocity.y += GRAVITY
		_:
#			pass
			_velocity.y += GRAVITY
		
	match state: # for flipping
		STATES.JUMP, STATES.FALL, STATES.ATTACK_AIR, STATES.GRAPPLE_LAUNCH_AIR, STATES.GRAPPLE_MOVE, STATES.IDLE:
			flip(_velocity.x, 0)
		_:
			flip(input.direction.x, 0)
			
	
	if state != STATES.GRAPPLE_MOVE:
		_velocity.x = clamp (_velocity.x, -SPEED_LIMIT.x, SPEED_LIMIT.x)
		_velocity.y = clamp (_velocity.y, -SPEED_LIMIT.y, SPEED_LIMIT.y)
	
	_velocity = move_and_slide(_velocity, Vector2(0, -1))
	
	pivot_pos.look_at(get_global_mouse_position())	
	
	prev_state = state
	_prev_dir = input.direction
	_prev_velocity = _velocity
	
	if _velocity.y > 0 and not (state == STATES.ATTACK_AIR and animation.is_playing()):
		change_state(EVENTS.FALL)

func enter_state():
	match state:
		STATES.IDLE:
			animation.play("idle")
#			animation.play("idle")
		STATES.WALK:
			animation.play("walk")
#			animation.play("walk")
		STATES.JUMP:
				is_holding_jump = true
				_velocity.y = JUMP_HEIGHT
				animation.play("jump")
		STATES.FALL:
			is_holding_jump = false
			animation.play("fall")
		STATES.FLY:
			finish_hook()
		STATES.GRAPPLE_LAUNCH_AIR, STATES.GRAPPLE_LAUNCH_GROUND:
			#creating hoook
			if true: #checking if hook area is in monster
				var hook = g_hook_resource.instance()

				hook.setup(Utils.get_dir(g_hook_pos, pivot_pos), g_hook_pos.global_position, get_global_mouse_position(), self)
				current_hook = hook
				get_parent().get_parent().add_child(hook)
			continue
		STATES.GRAPPLE_LAUNCH_GROUND:
			pass
#			_velocity.x = 0	
#			animation.play("idle")
		STATES.GRAPPLE_MOVE:
			animation.play("jump")		
		STATES.ATTACK_GROUND:
#			_velocity.x = 0	
			animation.play("attack_swing")
		STATES.ATTACK_AIR:
			animation.play("attack_swing")
#		STATES.ROLL:

static func get_raw_input(state):
	return {
		direction = Utils.get_input_direction(),
		is_jumping = Input.is_action_pressed("jump"),
		is_attacking = Input.is_action_just_pressed("attack"),
		is_using_hook = Input.is_action_just_pressed("launch_grappling_hook"),
		is_rolling = Input.is_action_just_pressed("roll")
	}
	
func get_event(input): #only events based on input here!
	var e = EVENTS.INVALID
	
	if input.is_jumping:
		jump_buffer_timer.start()
	
	if input.is_attacking or state == STATES.ATTACK_GROUND or state == STATES.ATTACK_AIR:
		e = EVENTS.ATTACK
	elif input.is_using_hook:
		if state == STATES.GRAPPLE_MOVE:
			e = EVENTS.GRAPPLE_DONE
		else:
			var space_state = get_world_2d().direct_space_state
			var result = space_state.intersect_point(g_hook_pos.position)
			e = EVENTS.GRAPPLE_LAUNCH
	elif (not jump_buffer_timer.is_stopped()) and (is_on_floor() or can_coyote_jump):
		e = EVENTS.JUMP
	elif input.is_rolling:
		e = EVENTS.ROLL
	elif input.direction != Vector2.ZERO:
		e = EVENTS.WALK
	else:
		e = EVENTS.STOP	
	return e	
	
func finish_hook():
	if current_hook_wr.get_ref() and current_hook != null:
		current_hook.fade_away()
		current_hook = null
		change_state(EVENTS.GRAPPLE_DONE)

func add_friction(friction = FRICTION):
	if _velocity.x > 0:
		_velocity.x = max(_velocity.x - friction, 0)
	elif _velocity.x < 0:
		_velocity.x = min(_velocity.x + friction, 0)
	
func flip(val1, val2):
	if val1 < val2:
		sprite.scale.x = -current_scale.x		
		is_flipped = true
	elif val1 > val2:
		sprite.scale.x = current_scale.x	
		is_flipped = false

func hook_launch_outcome(outcome, hook):
	match outcome:
		"success":
			change_state(EVENTS.GRAPPLE_SUCCESS)
			current_hook = hook	
			current_hook_wr = weakref(hook)
		"failure":
			change_state(EVENTS.GRAPPLE_FAIL)
			hook.retract()
			current_hook = null

func hook_move_outcome(outcome = "failure"):
	match outcome:
		"failure":
			if current_hook_wr.get_ref():
				current_hook.fade_away()
				current_hook = null

func hit():
	healthUI.update_health()
	hurt_animation.play_hurt()

func die():
	#TODO add death screen
	hook_move_outcome("failure")
	queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "attack_swing":
		enemies_damaged = []
		change_state(EVENTS.STOP)
		print("DONE WITH ATTACK")
	elif anim_name == "fall":
		animation.play("fall_continue")

func _on_CoyoteGroundTimer_timeout():
	can_coyote_jump = false


func _on_Sprite_animation_finished():
	if sprite.get_animation() == "attack_swing":
		enemies_damaged = []
		change_state(EVENTS.STOP)
		print("DONE WITH ATTACK")
	elif sprite.get_animation() == "fall":
		animation.play("fall_continue")
