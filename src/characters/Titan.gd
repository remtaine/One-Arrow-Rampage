extends "res://src/characters/Character.gd"

var STATES = {
	IDLE = "idle",
	ROAM = "roam",
	CHASE = "chase",
	CHASE_DEFEND = "defend",	
	ATTACK = "attack",
	FALL = "fall",
	DIE = "DIE"
}

enum EVENTS {
	INVALID=-1,
	STOP,
	ROAM,
	DEFEND,
	ATTACK,
	FALL,
	LAND,
	DIE
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

const SPEED = 500
const TITAN_SCALE = 2

export var main_hp = false
export var enemy_scale = 8

export var color = Color(255,0,0,1)

onready var sprite = $AnimatedSprite
onready var animation = $AnimationPlayer

onready var roam_range = $Range/RoamArea2D
var current_phase = PHASE.ZERO
var current_scale_x
var enemies_damaged = []

var _speed = SPEED
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
		[STATES.ROAM, EVENTS.ATTACK]: STATES.ATTACK, #TEMP! TODO remove once chase state implemented

		[STATES.CHASE, EVENTS.ATTACK]: STATES.ATTACK,

		[STATES.ATTACK, EVENTS.STOP]: STATES.CHASE,
		
		[STATES.FALL, EVENTS.LAND]: STATES.IDLE,
		[STATES.IDLE, EVENTS.FALL]: STATES.FALL,
		[STATES.ROAM, EVENTS.FALL]: STATES.FALL,
		
		[STATES.IDLE, EVENTS.ROAM]: STATES.ROAM,
		
		[STATES.IDLE, EVENTS.DIE]: STATES.DIE,
		[STATES.ROAM, EVENTS.DIE]: STATES.DIE, #TEMP! TODO remove once chase state implemented
		[STATES.CHASE, EVENTS.DIE]: STATES.DIE,
		[STATES.CHASE_DEFEND, EVENTS.DIE]: STATES.DIE,
		[STATES.ATTACK, EVENTS.DIE]: STATES.DIE,		
		[STATES.FALL, EVENTS.DIE]: STATES.DIE,

	}

func _ready():
	instance_name = "titan"
#	max_hp *= TITAN_SCALE #to make titans stronger
#	max_hp *= enemy_scale/8.0
#	hp = max_hp
	_dir.x *= -1
	if main_hp:
		hp_bar = $CanvasLayer/HealthBarBottom
		$Overhead/HealthBarOverhead.visible = false
	else:
		hp_bar = $Overhead/HealthBarOverhead
		$CanvasLayer/HealthBarBottom.visible = false
#		$Overhead/Label.visible = false
#	hp_bar.set_min(0)
#	hp_bar.set_max(max_hp)	
#	hp_bar.set_value(hp)
#	print("ENEMY MAX HP AT ", max_hp)
	
	current_scale_x = sprite.scale.x
	state = STATES.ATTACK

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
			pass
#			var temp = roam_range.get_overlapping_bodies()
#			if temp.size() == 0 and is_on_floor():
#				_dir.x *= -1
#			_velocity.x = _speed * input.direction.x
#			animation.play("walk")
#			flip(_dir.x < 0)
			#TODO check if next tile is 
		STATES.FALL:
			_velocity.x = _prev_velocity.x
			if is_on_floor():
				change_state(EVENTS.LAND)	
		STATES.ATTACK:
			_velocity.x = 0
			match current_attack_pattern:
				ATTACK_PATTERNS.RUSH:
					animation.play("attack")

	_velocity.y += 10 # for gravity
	_velocity = move_and_slide(_velocity, Vector2(0, -1))

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
		STATES.DIE:
			animation.play("die")			
func flip(val = true):
	if val:
		sprite.scale.x = -current_scale_x
		is_flipped = true
	else:
		sprite.scale.x = current_scale_x
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

func disable_hitboxes():
	$AnimatedSprite/Hitboxes/AttackHitbox.disable()
	
func hit():
	hp -= 1000
	hp_bar.set_value(hp)
	if hp <= 0:
		die()
	else:
		hurt_animation.play_hurt()
		print("HURT")

func die():
	disable_hitboxes()
	change_state(EVENTS.DIE)
	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "attack":
		enemies_damaged = []
		change_state(EVENTS.STOP)
	elif anim_name == "fall":
		animation.play("fall_continue")


func _on_AttackArea2D_body_entered(body):
	if body.is_in_group("human"):
		change_state(EVENTS.ATTACK)
		print("ATTACK BOI")
