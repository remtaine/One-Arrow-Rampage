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
	GRAPPLE_MOVE
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
	GRAPPLE_DONE
}

enum WEAPON {
	SWORD,
	BOW
}

const DAMAGE = {
	SWORD = 10.0,
	BOW = 5.0
}

const SPEED = {
	STATES.WALK: 300,
	STATES.RUN: 450,
	STATES.GRAPPLE_MOVE: 1500,
}

onready var sword = $Sprite/WeaponArm/Weapons/Sword
onready var bow = $Sprite/WeaponArm/Weapons/Bow
onready var shield = $Sprite/FreeArm/SideItems/Shield

onready var weapons = $Sprite/WeaponArm/Weapons
onready var side_items = $Sprite/FreeArm/SideItems

const HOOK_LEEWAY = 100
onready var pivot_pos = $CenterPivot
onready var g_hook_pos = $CenterPivot/GrapplingHookLaunchPosition
onready var g_hook_resource = preload("res://src/weapons/GrapplingHook.tscn")

onready var main_body = $Sprite/Body/MainBody
onready var climbing_body = $Sprite/Body/ClimbingBody

onready var animation = $AnimationPlayer

export var color = Color(255,0,0,1)

var enemies_damaged = []

var _speed = 0
var _velocity = Vector2.ZERO

var current_weapon = WEAPON.SWORD
var _collision_normal = Vector2()
var _last_input_direction = Vector2.ZERO

var current_hook
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
		
		[STATES.GRAPPLE_LAUNCH, EVENTS.GRAPPLE_SUCCESS]: STATES.GRAPPLE_MOVE,
		[STATES.GRAPPLE_MOVE, EVENTS.GRAPPLE_DONE]: STATES.IDLE,
	}

func _ready():
	set_territory_text()	
	$Camera2D.current = true

func _physics_process(delta):
	for i in get_slide_count():
		#changing collisions for ground object
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("tiles"):
			collider.change_color(self)
	
	
	var input = get_raw_input(state)
	var event = get_event(input)
	change_state(event)
	
	if input.is_changing_weapon:
		change_weapon()
		
	match state:
		STATES.IDLE:
			animation.play("idle")
		STATES.WALK, STATES.RUN:
			animation.play("walk")
			flip(input.direction.x < 0)
			_velocity.x = _speed * input.direction.x
		STATES.ATTACK, STATES.GRAPPLE_LAUNCH:
			_velocity.x = 0
		STATES.GRAPPLE_MOVE:
			var temp = current_hook.global_position.x < global_position.x
			flip(temp)

			var _dir = get_dir(current_hook, self)
			_velocity = _speed * _dir
			if current_hook.global_position.distance_to(global_position) < HOOK_LEEWAY:
				print("GRAPPLE HOOK DONE")
#				rotation = 0
				change_state(EVENTS.GRAPPLE_DONE)
				current_hook.fade_away()
				current_hook = null
				_velocity = Vector2.ZERO

	if state == STATES.GRAPPLE_MOVE:
		_velocity = move_and_slide(_velocity)
	else:
		_velocity.y += 10 # for gravity
		_velocity = move_and_slide(_velocity)
	pivot_pos.look_at(get_global_mouse_position())

func enter_state():
	print("STATE IS NOW: ", state)
	match state:
		STATES.IDLE:
			_velocity.x = 0
			self._speed = 0
		STATES.CLIMB:
			is_climbing = true #TODO not needed
		STATES.GRAPPLE_LAUNCH:
			#spawn launcher at g_hook_pos
			var hook = g_hook_resource.instance()
#			hook.position = g_hook_pos.position
			hook.setup(get_dir(g_hook_pos, pivot_pos), g_hook_pos.global_position, pivot_pos.rotation, self)
			get_parent().get_parent().add_child(hook)
			print("LAUNCHED HOOK")
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
		is_running = Input.is_action_pressed("run"),
		is_changing_weapon = Input.is_action_just_pressed("change_weapon") or Input.is_action_just_released("change_weapon_wheel"),
		is_attacking = Input.is_action_just_pressed("attack"),
		is_going_up = Input.is_action_pressed("move_up"),
		is_launching_grappling_hook = Input.is_action_just_pressed("launch_grappling_hook")
	}

static func get_input_direction(event = Input):
	return Vector2(
		float(event.is_action_pressed("move_right")) - float(event.is_action_pressed("move_left")),
		0).normalized()

func hook_outcome(outcome, hook):
	match outcome:
		"success":
			change_state(EVENTS.GRAPPLE_SUCCESS)
			print("HOOOKED SUCCESFULLY!!!")
		"failure":
			pass
	current_hook = hook

func get_event(input):
	"""
	Converts the player's input to events. The state machine
	uses these events to trigger transitions from one state to another.
	"""
	var event = EVENTS.INVALID
	
	if input.is_launching_grappling_hook or state == STATES.GRAPPLE_LAUNCH:
#		print("EVENT IS LAUNCHED HOOK")
		return EVENTS.GRAPPLE_LAUNCH
	if input.is_going_up:
		if true: #TODO: check if overlapping a ladder
			pass #TODO: return EVENTS.CLIMB
		else:
			pass #TODO: return EVENTS.JUMP
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

func _on_SwordHitbox_body_entered(body):
	#damage enemy
	if body.is_in_group("characters") and not enemies_damaged.has(body):
		enemies_damaged.append(body)
		body.hit(DAMAGE.SWORD * territory/100)
