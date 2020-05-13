extends "res://src/characters/Character.gd"

enum STATES {
	IDLE,
	WALK,
	JUMP,
	FALL,
	GRAPPLE_LAUNCH_AIR,
	GRAPPLE_LAUNCH_GROUND,
	GRAPPLE_MOVE,
	FLY,
	ATTACK_GROUND,
	ATTACK_AIR,
	ROLL,
}

enum EVENTS {
	INVALID=-1,
	STOP,
	WALK,
	JUMP,
	ATTACK,
	FALL,
	GRAPPLE_LAUNCH,
	GRAPPLE_SUCCESS,
	GRAPPLE_FAIL,
	GRAPPLE_DONE,
	ROLL,
	LAND
}

enum WEAPON {
	SWORD,
	BOW
}

const DAMAGE =  10.0

const SPEED = 40
const GRAPPLE_SPEED = 1350

const SPEED_LIMIT = 720
const FRICTION = 25
const AIR_FRICTION = 5
const TURN_STRENGTH = 1.5
const AIR_CONTROL = 0.4
const GRAVITY = 10
const JUMP_DEFICIENCY = 1

const JUMP_HEIGHT = -600
onready var sprite = $Sprite #shuld be #Sprite
onready var sword = $Sprite/WeaponArm/Weapons/Sword
onready var bow = $Sprite/WeaponArm/Weapons/Bow
onready var shield = $Sprite/FreeArm/SideItems/Shield

onready var weapons = $Sprite/WeaponArm/Weapons
onready var side_items = $Sprite/FreeArm/SideItems

const HOOK_LEEWAY = 135
const HOOK_VELOCITY_DAMPENING = 0.7
onready var pivot_pos = $Sprite/CenterPivot
onready var g_hook_pos = $Sprite/CenterPivot/ProjectileLaunchPosition1
onready var g_hook_resource = preload("res://src/weapons/GrapplingHook.tscn")

onready var main_body = $Sprite/Body/MainBody
onready var climbing_body = $Sprite/Body/ClimbingBody

var can_coyote_jump = false
onready var coyote_timer = $GameFeel/CoyoteGroundTimer
onready var jump_buffer_timer = $GameFeel/JumpBufferTimer

onready var animation = $AnimationPlayer

export var color = Color(255,0,0,1)

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
var territory = 0.0 setget set_territory

func _init():	
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
		[STATES.ATTACK_AIR, EVENTS.LAND]:STATES.IDLE,
		
		[STATES.ROLL, EVENTS.ROLL]:STATES.IDLE,
	}

func _ready():
	set_territory_text()	
	$Camera2D.current = true

func _physics_process(delta):
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("tiles"):
			collider.change_color(self)
			
	var input = get_raw_input(state)
	var event = get_event(input)
	change_state(event)

	if is_on_floor():
		can_coyote_jump = true
		coyote_timer.start()
	elif not coyote_timer.is_stopped():
		coyote_timer.start()
	_dir = input.direction
	
	match state:
		STATES.IDLE:
			add_friction()
		STATES.WALK, STATES.GRAPPLE_LAUNCH_GROUND, STATES.ATTACK_GROUND:
			if input.direction.x * _velocity.x < 0:
				_velocity.x += SPEED * _dir.x * TURN_STRENGTH
			else:
				_velocity.x += SPEED * _dir.x
			
		STATES.JUMP, STATES.FALL, STATES.GRAPPLE_LAUNCH_AIR:
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
		STATES.JUMP, STATES.GRAPPLE_LAUNCH_AIR, STATES.ATTACK_AIR, STATES.FLY:
			if not input.is_jumping: #whil
				is_holding_jump = false
			if not is_holding_jump:
				_velocity.y += GRAVITY * JUMP_DEFICIENCY * 1.2
			if is_on_floor():
				change_state(EVENTS.LAND)
		STATES.FALL:
#			if not (can_coyote_jump and not is_on_floor()):
			_velocity.y += GRAVITY * JUMP_DEFICIENCY * 1.7
			if is_on_floor():
				change_state(EVENTS.LAND)
#		STATES.GRAPPLE_LAUNCH_AIR:
#		STATES.GRAPPLE_LAUNCH_GROUND:
		STATES.GRAPPLE_MOVE:
			_dir = get_dir(current_hook, self)
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
			_velocity.y += GRAVITY
				
		
	match state: # for flipping
		STATES.JUMP, STATES.FALL, STATES.ATTACK_AIR, STATES.GRAPPLE_LAUNCH_AIR, STATES.GRAPPLE_MOVE, STATES.IDLE:
			flip(_velocity.x, 0)
		_:
			flip(input.direction.x, 0)
			
	
	if state != STATES.GRAPPLE_MOVE:
		_velocity.x = clamp (_velocity.x, -SPEED_LIMIT, SPEED_LIMIT)
		_velocity.y = clamp (_velocity.y, -SPEED_LIMIT, SPEED_LIMIT)
	
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
				animation.play("grapple_move")
		STATES.FALL:
			is_holding_jump = false
			animation.play("fall")
		STATES.FLY:
			finish_hook()
		STATES.GRAPPLE_LAUNCH_AIR, STATES.GRAPPLE_LAUNCH_GROUND:
			#creating hoook
			if true: #checking if hook area is in monster
				var hook = g_hook_resource.instance()

				hook.setup(get_dir(g_hook_pos, pivot_pos), g_hook_pos.global_position, get_global_mouse_position(), self)
				current_hook = hook
				get_parent().get_parent().add_child(hook)
			continue
		STATES.GRAPPLE_LAUNCH_GROUND:
#			_velocity.x = 0	
			animation.play("idle")
		STATES.GRAPPLE_MOVE:
			if _velocity.y < 0:
				animation.play("grapple_move")
			else:
				animation.play("fall")			
		STATES.ATTACK_GROUND:
			animation.play("attack_swing")
		STATES.ATTACK_AIR:
			animation.play("attack_swing")
#		STATES.ROLL:

static func get_raw_input(state):
	return {
		direction = get_input_direction(),
		is_jumping = Input.is_action_pressed("jump"),
		is_attacking = Input.is_action_just_pressed("attack"),
		is_using_hook = Input.is_action_just_pressed("launch_grappling_hook"),
		is_rolling = Input.is_action_just_pressed("roll")
	}

static func get_input_direction(event = Input):
	var d = Vector2(float(event.is_action_pressed("move_right")) - float(event.is_action_pressed("move_left")),
		0).normalized()	
	return d
	
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
#			print("RESULTS ", result)
			e = EVENTS.GRAPPLE_LAUNCH
	elif (not jump_buffer_timer.is_stopped()) and (is_on_floor() or can_coyote_jump):
		e = EVENTS.JUMP
	elif input.is_rolling:
		e = EVENTS.ROLL
	elif input.direction != Vector2.ZERO:
		e = EVENTS.WALK
	elif state != STATES.FALL:
		e = EVENTS.STOP	
	return e	
	
func finish_hook():
	if current_hook_wr.get_ref():
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
		sprite.scale.x = -1		
		is_flipped = true
	elif val1 > val2:
		sprite.scale.x = 1
		is_flipped = false
			
static func get_dir(a1, a2):
	return (a1.global_position - a2.global_position).normalized()

func hook_launch_outcome(outcome, hook):
	match outcome:
		"success":
			change_state(EVENTS.GRAPPLE_SUCCESS)
			current_hook = hook	
			current_hook_wr = weakref(hook)
		"failure":
			change_state(EVENTS.GRAPPLE_FAIL)
			hook.queue_free()

func hook_move_outcome(outcome):
	match outcome:
		"failure":
			current_hook.queue_free()
			current_hook = null
			change_state(EVENTS.GRAPPLE_DONE)

func hide_weapons():
	weapons.visible = false
	side_items.visible = false

func change_body(body = "main"):
	match body:
		"main":
			main_body.visible = true
			climbing_body.visible = false
		"climbing":
			main_body.visible = false
			climbing_body.visible = true
	
func change_weapon():
	match current_weapon:
		WEAPON.SWORD:
			current_weapon = WEAPON.BOW
			sword.visible = false
			bow.visible = true
			shield.visible = false
		WEAPON.BOW:
			current_weapon = WEAPON.SWORD
			sword.visible = true
			bow.visible = false
			shield.visible = true
	
func set_territory(val):
	territory += val
	set_territory_text()
	
func set_territory_text(text = territory):
	$Territory.text = ": " + str(text)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "attack_swing":
		enemies_damaged = []
		change_state(EVENTS.STOP)
	elif anim_name == "fall":
		animation.play("fall_continue")

func _on_CoyoteGroundTimer_timeout():
	can_coyote_jump = false
#	print("COYOTE JUMP OFF")
