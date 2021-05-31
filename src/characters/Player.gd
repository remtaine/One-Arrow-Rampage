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
	DIE = "DIE"
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
	LAND = "player event land",
	DIE = "player event DIE"
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

const HOOK_LEEWAY = 50
const HOOK_VELOCITY_DAMPENING = 0.7

onready var camera = $Camera2D
onready var sprite = $AnimatedSprite #shuld be #Sprite
onready var animation = $AnimationPlayer

onready var pivot_pos = $CenterPivot
onready var g_hook_pos = $CenterPivot/ProjectileLaunchPosition1
onready var g_hook_aim = $CenterPivot/ProjectileLaunchPosition1/Aim
onready var g_hook_resource = preload("res://src/weapons/GrapplingHook.tscn")
onready var screenshake = $Camera2D/ScreenShakeGenerator

onready var hurt_audio1 = $Audio/HurtAudio1
onready var hurt_audio2 = $Audio/HurtAudio2
onready var hurt_audios = [hurt_audio1, hurt_audio2]
onready var death_audio = $Audio/DeathAudio
onready var theme_music = $Audio/ThemeMusic
onready var attack_audio = $Audio/AttackAudio
onready var hurt_audio_separate = $Audio/HurtAudioSeparate

onready var jump_audio = $Audio/JumpAudio
onready var land_audio = $Audio/LandAudio

onready var footsteps_audio1 = $Audio/FootstepsAudio1
onready var footsteps_audio2 = $Audio/FootstepsAudio2
onready var footsteps_audio3 = $Audio/FootstepsAudio3
onready var footsteps_audio4 = $Audio/FootstepsAudio4
onready var footsteps_audios = [footsteps_audio1, footsteps_audio2, footsteps_audio3, footsteps_audio4] 

onready var error_audio = $Audio/ErrorAudio

onready var coyote_timer = $Timers/CoyoteGroundTimer
onready var jump_buffer_timer = $Timers/JumpBufferTimer
onready var invulnerability_timer = $Timers/InvulnerabilityTimer

onready var grapple_bar = $UI/GrappleCDBar
var grapple_time_started = -1.0
var grapple_time_since = 0.0
var grapple_time_total = 1000.0 #milliseconds
var grapple_bar_off = false

var crosshair_on = load("res://32x32crosshair on.png")
var crosshair_off = load("res://32x32 crosshair off.png")

export var color = Color(255,0,0,1)
export var is_invulnerable = false

var last_clicked_mouse_pos
var last_global_pos
var current_scale = 1
var can_coyote_jump = false

var enemies_damaged = []

var input
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
#var current_hook_wr
var is_running = false
var is_holding_jump = false
var is_flipped = false

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
		[STATES.ATTACK_AIR, EVENTS.LAND]:STATES.ATTACK_GROUND,
		
		[STATES.ROLL, EVENTS.ROLL]:STATES.IDLE,
		
		[STATES.IDLE, EVENTS.DIE]:STATES.DIE,
		[STATES.WALK, EVENTS.DIE]:STATES.DIE,
		[STATES.JUMP, EVENTS.DIE]:STATES.DIE,
		[STATES.FALL, EVENTS.DIE]:STATES.DIE,
		[STATES.GRAPPLE_LAUNCH_AIR, EVENTS.DIE]:STATES.DIE,
		[STATES.GRAPPLE_LAUNCH_GROUND, EVENTS.DIE]:STATES.DIE,
		[STATES.GRAPPLE_MOVE, EVENTS.DIE]:STATES.DIE,
		[STATES.FLY, EVENTS.DIE]:STATES.DIE,
		[STATES.ATTACK_GROUND, EVENTS.DIE]:STATES.DIE,
		[STATES.ATTACK_AIR, EVENTS.DIE]:STATES.DIE,
		[STATES.ROLL, EVENTS.DIE]:STATES.DIE,
	}

func _ready():
	is_invulnerable = false
	is_alive = true
	Utils.has_won = false
	Utils.player = self
	Utils.camera_screenshake = screenshake
	state = STATES.IDLE
	current_scale = sprite.scale
	hp_bar.set_value(hp)
	instance_name = "player"
	grapple_bar.value = 0.0
	grapple_bar.max_value = grapple_time_total
	grapple_bar.value = 0.0

func _physics_process(delta):
	if grapple_bar_off:
		grapple_bar.value = grapple_time_since
	else:
		grapple_time_since = OS.get_ticks_msec() - grapple_time_started	
		grapple_bar.value = grapple_time_since
	if (grapple_time_since >= grapple_time_total):
		reset_grapple()
		
	if global_position.y > 640 and is_alive:
		if current_hook:# and current_hook_wr.get_ref():
			current_hook.fade_away()
		healthUI.update_health(0, true)
		die()
	input = get_raw_input(state)
	var event = get_event(input)
	change_state(event)

	_dir = input.direction
	
	match state:
		STATES.IDLE, STATES.GRAPPLE_LAUNCH_GROUND, STATES.ATTACK_GROUND, STATES.DIE:
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
		STATES.FALL:
			_velocity.y += GRAVITY * JUMP_DEFICIENCY * 1.7
			continue
#		STATES.ATTACK_AIR, STATES.ATTACK_GROUND:
#			flip(last_clicked_mouse_pos, global_position)
#			continue
		STATES.JUMP, STATES.GRAPPLE_LAUNCH_AIR, STATES.ATTACK_AIR, STATES.FLY, STATES.FALL:
			if is_on_floor():
				change_state(EVENTS.LAND)
		STATES.GRAPPLE_MOVE:
			if !current_hook:
				change_state(EVENTS.GRAPPLE_DONE)
			else:
				_dir = Utils.get_dir(current_hook, self)
				if current_hook.global_position.distance_to(global_position) < HOOK_LEEWAY:
					change_state(EVENTS.GRAPPLE_DONE)
				else:
					_velocity = GRAPPLE_SPEED * _dir

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
#		STATES.JUMP, STATES.FALL, STATES.ATTACK_AIR, STATES.GRAPPLE_LAUNCH_AIR, STATES.GRAPPLE_MOVE, STATES.IDLE:
		STATES.JUMP, STATES.FALL, STATES.GRAPPLE_MOVE:
			flip(_velocity.x, 0)
		STATES.ATTACK_AIR, STATES.ATTACK_GROUND, STATES.GRAPPLE_LAUNCH_AIR, STATES.GRAPPLE_LAUNCH_GROUND:
			flip(last_clicked_mouse_pos, last_global_pos)
		STATES.IDLE:
			if _velocity.x == 0:
				flip(get_global_mouse_position(), global_position)
			else:
				continue
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
	
	if Input.is_action_just_pressed("go_down"):
		position.y += 1

func enter_state():
	if prev_event == EVENTS.GRAPPLE_SUCCESS or prev_event == EVENTS.GRAPPLE_FAIL:
		grapple_time_started = OS.get_ticks_msec()
		grapple_bar_off = false
	match state:
		STATES.IDLE:
			if prev_event == EVENTS.LAND:
				land_audio.play()
				if input.direction == Vector2.ZERO:
					_velocity.x *= 0.65
			change_animation("idle")
#			animation.play("idle")
		STATES.WALK:
			change_animation("walk")
#			animation.play("walk")
		STATES.JUMP:
				jump_audio.play()
				is_holding_jump = true
				_velocity.y = JUMP_HEIGHT
				change_animation("jump")
		STATES.FALL:
			is_holding_jump = false
			change_animation("fall")
		STATES.FLY:
			finish_hook()
		STATES.GRAPPLE_LAUNCH_AIR, STATES.GRAPPLE_LAUNCH_GROUND:
			#creating hook
			last_clicked_mouse_pos = get_global_mouse_position()
			last_global_pos = global_position
			
			#creating hook
			var hook = g_hook_resource.instance()
			hook.setup(Utils.get_dir(g_hook_pos, pivot_pos), g_hook_pos.global_position, g_hook_aim.global_position, self)
			current_hook = hook
			get_parent().get_parent().add_child(hook)
			
			continue
		STATES.GRAPPLE_LAUNCH_GROUND:
			if animation.get_current_animation() == "walk":
				change_animation("idle")
#			_velocity.x = 0	
#			animation.play("idle")
		STATES.GRAPPLE_MOVE:
			change_animation("jump")		
		STATES.ATTACK_GROUND, STATES.ATTACK_AIR:
			last_clicked_mouse_pos = get_global_mouse_position()
			last_global_pos = global_position
			change_animation("attack_swing")
		STATES.DIE:
#			_velocity.x = 0
			theme_music.stop()
			death_audio.play()
			change_animation("die")

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
		if grapple_time_started < 0: #checking if hook area is in monster
			off_grapple()
#		elif grapple_timer.is_stopped(): #TODO try out what happens if I start timer on grapple_done or grapple_fail
			var space_state = get_world_2d().direct_space_state
			var result = space_state.intersect_point(g_hook_pos.position)
			Input.set_custom_mouse_cursor(crosshair_off)
			e = EVENTS.GRAPPLE_LAUNCH
		else:
			error_audio.play()
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
	if current_hook:
		current_hook.fade_away()
#		current_hook = null
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

func hook_launch_outcome(outcome, hook = current_hook):
	match outcome:
		"success":
			change_state(EVENTS.GRAPPLE_SUCCESS)
			current_hook = hook	
#			current_hook_wr = weakref(hook)
		"failure":
			change_state(EVENTS.GRAPPLE_FAIL)
			hook.retract()
#			current_hook = null

func hook_move_outcome(outcome = "failure"):
	match outcome:
		"failure":
			if current_hook:#_wr.get_ref():
				current_hook.fade_away()
#				current_hook = null

func hit():
	_velocity.x *= 0.3
	healthUI.update_health()
	hurt_animation.play_hurt()
	screenshake.start()
	Utils.play_audio(hurt_audios, "player")
	hurt_audio_separate.play()
	
	is_invulnerable = true
	invulnerability_timer.start()

func die():
	#TODO add death screen
	is_alive = false
	Utils.current_level.hide_instructions()
#	sprite.set_material(null)
	screenshake.start(1)
	change_state(EVENTS.DIE)
#	queue_free()

func off_grapple():
	grapple_time_since = 0.0
	grapple_bar.value = grapple_time_since
	grapple_bar_off = true
	
func reset_grapple():
	grapple_time_started = -1.0
	Input.set_custom_mouse_cursor(crosshair_on)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "attack_swing":
		change_state(EVENTS.STOP)
	elif anim_name == "fall":
		change_animation("fall_continue")
	elif anim_name == "die":
		if not Utils.has_won:
			$UI/YouDiedText.appear()
		#TODO add death screen

func _on_CoyoteGroundTimer_timeout():
	can_coyote_jump = false

func _on_Sprite_animation_finished():
	if sprite.get_animation() == "attack_swing":
		enemies_damaged = []
		change_state(EVENTS.STOP)
		print("DONE WITH ATTACK")
	elif sprite.get_animation() == "fall":
		change_animation("fall_continue")

func change_animation(anim):
	animation.play(anim)
	match anim:
		"idle":
			animation.set_speed_scale(0.7)
		"attack_swing":
			animation.set_speed_scale(1.5)			
		"die":
			animation.set_speed_scale(1.3)			
	
		_:
			animation.set_speed_scale(1)

func play_footsteps_audio():
	Utils.play_audio(footsteps_audios)

func play_attack_audio():
	attack_audio.play()
	
func _on_InvulnerabilityTimer_timeout():
	is_invulnerable = false

func _on_grappling_hook_removed():
	current_hook = null
#	grapp
