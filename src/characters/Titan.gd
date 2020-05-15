extends "res://src/characters/Character.gd"

var STATES = {
	IDLE = "idle",
	CHANGE_PHASE = "change phase",
	ROAM = "roam",
	CHASE = "chase",
	ATTACK = "attack",
	FALL = "fall",
}

enum EVENTS {
	INVALID=-1,
	STOP,
	ROAM,
	TARGET,
	ATTACK,
	FALL,
	LAND
}

var PHASE = {
	ZERO = 0,
	ONE = 1,
	TWO = 2,
	THREE = 3
}

enum ATTACK_PATTERNS {
	INVALID = -1,
	RUSH,
}
const DAMAGE = 10

var SPEED = {
	STATES.ROAM: 300,
	STATES.CHASE: 500
}
const TITAN_SCALE = 2

export var main_hp = false
export var enemy_scale = 8

onready var sword = $Sprite/WeaponArm/Weapons/Sword
onready var bow = $Sprite/WeaponArm/Weapons/Bow
onready var shield = $Sprite/FreeArm/SideItems/Shield

onready var weapons = $Sprite/WeaponArm/Weapons
onready var side_items = $Sprite/FreeArm/SideItems

const HOOK_LEEWAY = 100
const HOOK_VELOCITY_DAMPENING = 0.7
onready var pivot_pos = $CenterPivot
onready var g_hook_pos = $CenterPivot/ProjectileLaunchPosition1
onready var g_hook_resource = preload("res://src/weapons/GrapplingHook.tscn")

onready var main_body = $Sprite/Body/MainBody
onready var climbing_body = $Sprite/Body/ClimbingBody

onready var coyote_timer = $GameFeel/CoyoteGroundTimer
onready var jump_buffer_timer = $GameFeel/JumpBufferTimer

onready var animation = $AnimationPlayer

export var color = Color(255,0,0,1)

onready var roam_range = $Sprite/Range/RoamArea2D
var current_phase = PHASE.ZERO
var current_scale_x
var enemies_damaged = []

var _speed = SPEED[STATES.ROAM]
var _velocity = Vector2.ZERO
var _dir = Vector2(1,0)
var _prev_velocity = Vector2.ZERO

var current_attack_pattern = ATTACK_PATTERNS.RUSH
var _collision_normal = Vector2()
var _last_input_direction = Vector2.ZERO

var is_climbing = false #TODO dont actually need this, use state instead
var is_running = false

var is_flipped = false

func _init():	
	_transitions = {
		[STATES.IDLE, EVENTS.ROAM]: STATES.ROAM,
		
		[STATES.ROAM, EVENTS.STOP]: STATES.IDLE,
		[STATES.ROAM, EVENTS.TARGET]: STATES.CHASE,
		[STATES.ROAM, EVENTS.ATTACK]: STATES.ATTACK, #TEMP! TODO remove once chase state implemented

		[STATES.CHASE, EVENTS.ATTACK]: STATES.ATTACK,

		[STATES.ATTACK, EVENTS.STOP]: STATES.CHASE,
		
		[STATES.FALL, EVENTS.LAND]: STATES.IDLE,
		[STATES.IDLE, EVENTS.FALL]: STATES.FALL,
		[STATES.ROAM, EVENTS.FALL]: STATES.FALL,
	}

func _ready():
	max_hp *= TITAN_SCALE #to make titans stronger
	scale.x = enemy_scale
	scale.y = enemy_scale
	max_hp *= enemy_scale/8.0
	hp = max_hp
	
	if main_hp:
		hp_bar = $CanvasLayer/HealthBarBottom
		$Overhead/HealthBarOverhead.visible = false
	else:
		hp_bar = $Overhead/HealthBarOverhead
		$CanvasLayer/HealthBarBottom.visible = false
#		$Overhead/Label.visible = false
	hp_bar.set_min(0)
	hp_bar.set_max(max_hp)	
	hp_bar.set_value(hp)
	print("ENEMY MAX HP AT ", max_hp)
	
	current_scale_x = $Sprite.scale.x
	state = STATES.ROAM

func _physics_process(delta):
	var slides = get_slide_count()
	for i in slides:
		#changing collisions for ground object
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider == null:
			pass
		elif collider.has_method("change_color"):
			collider.change_color(self)
	
	var input = get_raw_input(state)
	var event = get_event(input)
	change_state(event)
	match state:
		STATES.IDLE:
			animation.play("idle")
		STATES.ROAM:
			var temp = roam_range.get_overlapping_bodies()
			if temp.size() == 0:
				_dir.x *= -1
			_velocity.x = _speed * input.direction.x
			animation.play("walk")
			flip(_dir.x < 0)
			#TODO check if next tile is 
		STATES.FALL:
			_velocity.x = _prev_velocity.x
			if is_on_floor():
				change_state(EVENTS.LAND)	
		STATES.ATTACK:
			_velocity.x = 0
			match current_attack_pattern:
				ATTACK_PATTERNS.RUSH:
					animation.play("attack_rush")

	_velocity.y += 10 # for gravity
	_velocity = move_and_slide(_velocity, Vector2(0, -1))
	pivot_pos.look_at(get_global_mouse_position())

func enter_state():
	match state:
		STATES.IDLE:
			pass
		STATES.FALL:
			if animation.current_animation != "fall_continue":
				animation.play("fall")
		STATES.ROAM:
			is_running = false
		STATES.ATTACK:
			randomize()
			current_attack_pattern = 0
					
func flip(val = true):
	if val:
		$Sprite.scale.x = -current_scale_x
		is_flipped = true
	else:
		$Sprite.scale.x = current_scale_x
		is_flipped = false
			
static func get_dir(a1, a2):
	return (a1.global_position - a2.global_position).normalized()

func get_raw_input(state):
	return {
		direction = _dir,
		is_running = false,
		is_changing_weapon = false,
		is_attacking = false,
		is_going_up = false,
		is_launching_grappling_hook = false
	}

func get_event(input):
	"""
	Converts the player's input to events. The state machine
	uses these events to trigger transitions from one state to another.
	"""
	var event = EVENTS.INVALID

	if input.is_attacking or state == STATES.ATTACK:
		event = EVENTS.ATTACK
	elif input.direction == Vector2():
		event = EVENTS.STOP
	else:
		event = EVENTS.ROAM

	return event

func die():
	queue_free()
	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "attack_swing":
		enemies_damaged = []
		change_state(EVENTS.STOP)
	elif anim_name == "fall":
		animation.play("fall_continue")


func _on_AttackArea2D_body_entered(body):
	if body.is_in_group("human"):
		change_state(EVENTS.ATTACK)
		print("ATTACK BOI")
