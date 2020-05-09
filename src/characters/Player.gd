extends "res://src/characters/Character.gd"

enum STATES {
	IDLE,
	WALK,
	RUN,
	ATTACK,
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
	ATTACK,
	JUMP,
	BUMP,
	FALL,
	RESPAWN
}

enum WEAPON {
	SWORD,
	BOW
}

var DAMAGE = {
	SWORD = 10.0,
	BOW = 5.0
}

const SPEED = {
	STATES.WALK: 300,
	STATES.RUN: 450
}

onready var sword = $Sprite/WeaponArm/Sword
onready var bow = $Sprite/WeaponArm/Bow
onready var shield = $Sprite/FreeArm/Shield

onready var animation = $AnimationPlayer

export var color = Color(255,0,0,1)

var enemies_damaged = []
var _speed = 0
var _velocity = Vector2.ZERO
var current_weapon = WEAPON.SWORD
var _collision_normal = Vector2()
var _last_input_direction = Vector2.ZERO
var is_running = false
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
	
	if input.is_changing_weapon:
		change_weapon()
		
	match state:
		STATES.IDLE:
			animation.play("idle")
		STATES.WALK, STATES.RUN:
			animation.play("walk")
			if input.direction.x < 0:
				$Sprite.scale.x = -1
			else:
				$Sprite.scale.x = 1
			_velocity.x = _speed * input.direction.x
		STATES.ATTACK:
			_velocity.x = 0
	
	_velocity.y += 10
	_velocity = move_and_slide(_velocity)

func enter_state():
	match state:
		STATES.IDLE:
			_velocity.x = 0
			self._speed = 0

		STATES.WALK:
			_speed = SPEED[state]
			is_running = false
		STATES.RUN:
			_speed = SPEED[state]
			is_running = true
		STATES.ATTACK:
			match current_weapon:
				WEAPON.SWORD:
					animation.play("attack_swing")
				WEAPON.BOW:
					animation.play("attack_shoot")

static func get_raw_input(state):
	return {
		direction = get_input_direction(),
		is_running = Input.is_action_pressed("run"),
		is_changing_weapon = Input.is_action_just_pressed("change_weapon"),
		is_attacking = Input.is_mouse_button_pressed(BUTTON_LEFT)
	}

static func get_input_direction(event = Input):
	return Vector2(
		float(event.is_action_pressed("move_right")) - float(event.is_action_pressed("move_left")),
		float(event.is_action_pressed("move_down")) - float(event.is_action_pressed("move_up"))).normalized()

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
	elif is_running or (input.is_running and not is_running):
		event = EVENTS.RUN
	else:
		event = EVENTS.WALK

	return event

func change_weapon():
	print("WEAPON WAS PREVIOUSLY ", current_weapon)
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
	print("WEAPON CHANGED TO ", current_weapon)
	print ("Sword visibility: ", sword.visible)
	print ("Bow visibility: ", bow.visible)

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
