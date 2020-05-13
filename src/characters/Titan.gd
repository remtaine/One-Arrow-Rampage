extends "res://src/characters/Character.gd"

enum STATES {
	IDLE,
	WALK,
	RUN,
	ATTACK,
	JUMP,
	BUMP,
	FALL,
	CLIMB,
	RESPAWN,
	GRAPPLE_LAUNCH,
	GRAPPLE_MOVE,
}

enum EVENTS {
	INVALID=-1,
	STOP,
	IDLE,
	WALK,
	RUN,
	ATTACK,
	JUMP,
	BUMP,
	FALL,
	CLIMB,
	RESPAWN,
	GRAPPLE_LAUNCH,
	GRAPPLE_SUCCESS,
	GRAPPLE_DONE,
	GRAPPLE_FAILED_GROUND,
	GRAPPLE_FAILED_AIR,
	JUMP_DONE,
	LAND
}

enum WEAPON {
	SWORD,
	BOW
}

const DAMAGE = 100

const SPEED = {
	STATES.WALK: 200,
	STATES.RUN: 150,
	STATES.GRAPPLE_MOVE: 1000,
}

const JUMP_SPEED = 500
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

var enemies_damaged = []

var _speed = 0
var _velocity = Vector2.ZERO
var _prev_velocity = Vector2.ZERO

var current_weapon = WEAPON.SWORD
var _collision_normal = Vector2()
var _last_input_direction = Vector2.ZERO

var is_climbing = false #TODO dont actually need this, use state instead
var is_running = false

var is_flipped = false
var territory = 0 setget set_territory

func _init():	
	_transitions = {
		[STATES.IDLE, EVENTS.WALK]: STATES.WALK,
		[STATES.IDLE, EVENTS.RUN]: STATES.RUN,
		[STATES.WALK, EVENTS.STOP]: STATES.IDLE,
		[STATES.WALK, EVENTS.RUN]: STATES.RUN,
		[STATES.RUN, EVENTS.STOP]: STATES.IDLE,
		[STATES.RUN, EVENTS.WALK]: STATES.WALK,
		
		[STATES.IDLE, EVENTS.ATTACK]: STATES.ATTACK,
		[STATES.WALK, EVENTS.ATTACK]: STATES.ATTACK,
		[STATES.RUN, EVENTS.ATTACK]: STATES.ATTACK,
		[STATES.ATTACK, EVENTS.STOP]: STATES.IDLE,
		
		[STATES.IDLE, EVENTS.CLIMB]: STATES.CLIMB,
		[STATES.WALK, EVENTS.CLIMB]: STATES.CLIMB,
		[STATES.RUN, EVENTS.CLIMB]: STATES.CLIMB,
		
		[STATES.IDLE, EVENTS.GRAPPLE_LAUNCH]: STATES.GRAPPLE_LAUNCH,
		[STATES.WALK, EVENTS.GRAPPLE_LAUNCH]: STATES.GRAPPLE_LAUNCH,
		[STATES.RUN, EVENTS.GRAPPLE_LAUNCH]: STATES.GRAPPLE_LAUNCH,
		[STATES.JUMP, EVENTS.GRAPPLE_LAUNCH]: STATES.GRAPPLE_LAUNCH,
		[STATES.FALL, EVENTS.GRAPPLE_LAUNCH]: STATES.GRAPPLE_LAUNCH,
		
		[STATES.GRAPPLE_LAUNCH, EVENTS.GRAPPLE_SUCCESS]: STATES.GRAPPLE_MOVE,
		[STATES.GRAPPLE_LAUNCH, EVENTS.GRAPPLE_FAILED_GROUND]: STATES.IDLE,
		[STATES.GRAPPLE_LAUNCH, EVENTS.GRAPPLE_FAILED_AIR]: STATES.FALL,
		[STATES.GRAPPLE_MOVE, EVENTS.GRAPPLE_DONE]: STATES.FALL,
		
		[STATES.IDLE, EVENTS.JUMP]: STATES.JUMP,
		[STATES.WALK, EVENTS.JUMP]: STATES.JUMP,
		[STATES.RUN, EVENTS.JUMP]: STATES.JUMP,
		[STATES.JUMP, EVENTS.JUMP_DONE]: STATES.FALL,

		[STATES.FALL, EVENTS.LAND]: STATES.IDLE,
		[STATES.FALL, EVENTS.JUMP]: STATES.JUMP,
		[STATES.IDLE, EVENTS.FALL]: STATES.FALL,
		[STATES.WALK, EVENTS.FALL]: STATES.FALL,
		[STATES.RUN, EVENTS.FALL]: STATES.FALL,		
	}

func _ready():
	hp_bar = $CanvasLayer/HealthBar
	hp_bar.set_value(hp)
	set_territory_text()	

func _physics_process(delta):
	for i in get_slide_count():
		#changing collisions for ground object
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider == null:
			pass
		elif collider.is_in_group("tiles"):
			collider.change_color(self)
	
	if is_on_floor() and (state == STATES.RUN or state == STATES.WALK):
		coyote_timer.start()
	
	var input = get_raw_input(state)
	var event = get_event(input)
	change_state(event)
	
	if input.is_changing_weapon:
		change_weapon()
		
	match state:
		STATES.IDLE:
			animation.play("idle")
		STATES.WALK, STATES.RUN:
			_velocity.x = _speed * input.direction.x
			continue
		STATES.JUMP, STATES.FALL:
			_velocity.x = _prev_velocity.x
			continue
		STATES.JUMP:
			if _velocity.y > 0:
				change_state(EVENTS.JUMP_DONE)
		STATES.WALK, STATES.RUN:
			animation.play("walk")
			flip(input.direction.x < 0)
		STATES.ATTACK:
			_velocity.x = 0
		STATES.GRAPPLE_LAUNCH:
			pass
		STATES.FALL:
			if is_on_floor():
				change_state(EVENTS.LAND)

	if ((state == STATES.RUN or state == STATES.WALK) and not coyote_timer.is_stopped()) and not is_on_floor():
		pass
	else:
		_velocity.y += 10 # for gravity
	if false:
#		move_and_collide(_velocity * delta)		
		pass
	else:	
		_velocity = move_and_slide(_velocity, Vector2(0, -1))
	pivot_pos.look_at(get_global_mouse_position())

func enter_state():
	match state:
		STATES.IDLE:
			_velocity.x = 0
			self._speed = 0
		STATES.CLIMB:
			is_climbing = true #TODO not needed
		STATES.JUMP:
			animation.play("grapple_move")
			_velocity.y = -JUMP_SPEED
			match prev_state:
				STATES.FALL:
					pass #keep velocity
				STATES.RUN, STATES.WALK:
					pass
		STATES.FALL:
			if animation.current_animation != "fall_continue":
				animation.play("fall")
		STATES.GRAPPLE_LAUNCH:
			match prev_state:
				STATES.FALL, STATES.JUMP:
					pass #keep velocity
				STATES.RUN, STATES.WALK:
					_velocity.x = 0 #velocity = 0
			var hook = g_hook_resource.instance()
			hook.setup(get_dir(g_hook_pos, pivot_pos), g_hook_pos.global_position, pivot_pos.rotation, self)
			get_parent().get_parent().add_child(hook)
		STATES.WALK, STATES.RUN, STATES.GRAPPLE_MOVE:
			_speed = SPEED[state]
			continue
		STATES.GRAPPLE_MOVE:
			animation.play("grapple_move")
		STATES.WALK:
			is_running = false
		STATES.RUN:
			is_running = true
		STATES.ATTACK:
			match current_weapon:
				WEAPON.SWORD:
					animation.play("attack_swing")
				WEAPON.BOW:
					animation.play("attack_shoot")

func flip(val = true):
	if val:
		$Sprite.scale.x = -1
		is_flipped = true
	else:
		$Sprite.scale.x = 1
		is_flipped = false
			
static func get_dir(a1, a2):
	return (a1.global_position - a2.global_position).normalized()

static func get_raw_input(state):
	return {
		direction = get_input_direction(),
		is_running = false,
		is_changing_weapon = false,
		is_attacking = false,
		is_going_up = false,
		is_launching_grappling_hook = false
	}

static func get_input_direction(event = Input):
	return Vector2(-1,0).normalized()

func get_event(input):
	"""
	Converts the player's input to events. The state machine
	uses these events to trigger transitions from one state to another.
	"""
	var event = EVENTS.INVALID
	
	if input.is_going_up or not jump_buffer_timer.is_stopped():
		if (is_on_floor() or not coyote_timer.is_stopped()) and state != STATES.FALL:
			_prev_velocity = _velocity
			jump_buffer_timer.stop()
			return EVENTS.JUMP			
		elif state == STATES.FALL:
			jump_buffer_timer.start()	
	if input.is_launching_grappling_hook or state == STATES.GRAPPLE_LAUNCH:
		return EVENTS.GRAPPLE_LAUNCH
#	if _velocity.y > 0:
#		return EVENTS.FALL
	if input.is_attacking or state == STATES.ATTACK:
		event = EVENTS.ATTACK
	elif input.direction == Vector2():
		event = EVENTS.STOP
	elif is_running or (input.is_running and not is_running):
		event = EVENTS.RUN
	else:
		event = EVENTS.WALK

	return event

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
