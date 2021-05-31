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

var EVENTS = {
	INVALID = "EVENT INVALID",
	STOP = "EVENT STOP",
	ROAM = "EVENT ROAM",
	DEFEND = "EVENT DEFEND",
	CHASE = "EVENT CHASE",
	ATTACK = "EVENT ATTACK",
	FALL = "EVENT FALL",
	LAND = "EVENT LAND",
	DIE = "EVENT DIE"
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

const SPEED = 50
const CHASE_SPEED = 210
const TITAN_SCALE = 2

const CHASE_DISTANCE = 350
const ATTACK_DISTANCE = 40

export var main_hp = false
export var enemy_scale = 8

export var color = Color(255,0,0,1)

onready var sprite = $AnimatedSprite
onready var animation = $AnimationPlayer
onready var roam_range = $AnimatedSprite/Range/RoamArea2D
onready var death_audio = $DeathAudio

onready var death_audio1 = $DeathAudio1
onready var death_audio2 = $DeathAudio2
onready var death_audio3 = $DeathAudio3
onready var death_audios = [death_audio1, death_audio2, death_audio3]

var current_phase = PHASE.ZERO
var current_scale_x
var enemies_damaged = []

var has_seen_player = false
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
		[STATES.ROAM, EVENTS.CHASE]: STATES.CHASE,
		[STATES.CHASE, EVENTS.ROAM]: STATES.ROAM,
		[STATES.ROAM, EVENTS.ATTACK]: STATES.ATTACK, #TEMP! TODO remove once chase state implemented
#
		[STATES.CHASE, EVENTS.ATTACK]: STATES.ATTACK,
#
		[STATES.ATTACK, EVENTS.CHASE]: STATES.CHASE,
		[STATES.ATTACK, EVENTS.ROAM]: STATES.ROAM,
#
#		[STATES.FALL, EVENTS.LAND]: STATES.IDLE,
#		[STATES.IDLE, EVENTS.FALL]: STATES.FALL,
#		[STATES.ROAM, EVENTS.FALL]: STATES.FALL,
#
#		[STATES.IDLE, EVENTS.ROAM]: STATES.ROAM,
#
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
#	if main_hp:
#		hp_bar = $CanvasLayer/HealthBarBottom
#		$Overhead/HealthBarOverhead.visible = false
#	else:
	hp_bar = $Overhead/HealthBarOverhead
#	$CanvasdLayer/HealthBarBottom.visible = false
#	$Overhead/Label.visible = false
#	hp_bar.set_min(0)
#	hp_bar.set_max(max_hp)	
#	hp_bar.set_value(hp)
#	print("ENEMY MAX HP AT ", max_hp)
	
	current_scale_x = sprite.scale.x
	state = STATES.IDLE

func _physics_process(delta):
	var event = get_event()
	change_state(event)
	
	match state:
		STATES.IDLE:
			pass
		STATES.CHASE:
			if not is_facing(Utils.player) and $TurnTimer.is_stopped():
				_dir.x *= -1
				$TurnTimer.start()
			continue
		STATES.ROAM:
			continue
		STATES.DIE:
			pass
		STATES.FALL:
			if is_on_floor():
				change_state(EVENTS.LAND)	
		STATES.ATTACK:
			_velocity.x = 0
			match current_attack_pattern:
				ATTACK_PATTERNS.RUSH:
					change_animation("attack")
		_:
			var temp = roam_range.get_overlapping_bodies()
			if ((temp.size() == 0 and is_on_floor()) or is_on_wall()) and $TurnTimer.is_stopped():
				$TurnTimer.start()
				_dir.x *= -1
			_velocity.x = _speed * _dir.x
			flip(_dir.x < 0)

	_velocity.y += 10 # for gravity
	_velocity = move_and_slide(_velocity, Vector2(0, -1))

func enter_state():
	match state:
		STATES.IDLE:
			change_animation("idle")
		STATES.FALL:
			if animation.current_animation != "fall_continue":
				change_animation("fall")
		STATES.ROAM:
			hide_all_emotes()
			_speed = SPEED
			is_running = false
			change_animation("walk")
		STATES.CHASE:
			if prev_state == STATES.ROAM:	
				if (has_seen_player):
					display_emote("angry")
				else:
					display_emote("surprised")
			has_seen_player = true
			_speed = CHASE_SPEED
			is_running = true
			change_animation("walk")			
		STATES.ATTACK:
			hide_all_emotes()
			has_seen_player = true			
			change_animation("attack")
		STATES.DIE:
			if not has_seen_player:
				display_emote("stars")
			print("IM DYIN NOW")
			change_animation("die")			
func flip(val = true):
	if val:
		sprite.scale.x = -current_scale_x
		is_flipped = true
	else:
		sprite.scale.x = current_scale_x
		is_flipped = false
			
static func get_dir(a1, a2):
	return (a1.global_position - a2.global_position).normalized()

func get_event():
	"""
	Converts the player's input to events. The state machine
	uses these events to trigger transitions from one state to another.
	"""
	var event = EVENTS.INVALID
#	if animation.current_animation == "attack":
#		return EVENTS.ATTACK
	if animation.is_active() and animation.current_animation == "attack":
		return EVENTS.ATTACK
	
	if global_position.distance_to(Utils.player.global_position) < ATTACK_DISTANCE and near_on_y_plane(): #facing player and within range
		if is_facing(Utils.player):
			return EVENTS.ATTACK
	if global_position.distance_to(Utils.player.global_position) < CHASE_DISTANCE and near_on_y_plane(): #within chase range
		if is_facing(Utils.player) or has_seen_player:
			return EVENTS.CHASE
	return EVENTS.ROAM

func near_on_y_plane():
	return abs(Utils.player.global_position.y - global_position.y) < 50.0

func hide_all_emotes():
	for child in $AnimatedSprite/Emotes.get_children():
		child.visible = false

func display_emote(emotion):
	hide_all_emotes()
	match emotion:
		"surprised":
			$AnimatedSprite/Emotes/emote_exclamation.visible = true
		"angry":
			$AnimatedSprite/Emotes/emote_anger.visible = true
		"stars":
			$AnimatedSprite/Emotes/emote_stars.visible = true
	$EmotesTimer.start()
		
func is_facing(val):
	if (is_flipped and global_position.x >= val.global_position.x):
		return true
	if (not is_flipped and global_position.x <= val.global_position.x):
		return true		
	return false
			
func disable_hitboxes():
	$AnimatedSprite/Hitboxes/AttackHitbox.disable()
	
func hit():
	hp -= 1000
	$AnimationPlayer/HurtAnimationPlayer.play("hurt")
	hp_bar.set_value(hp)
	Utils.freeze_frame()
	if hp <= 0:
		die()
	else:
		hurt_animation.play_hurt()
		print("HURT")

func die():
	Utils.current_level.update_killed_label()
	if not has_seen_player:
		Utils.current_level.update_silent_killed_label()
	_velocity.x = 0
	disable_hitboxes()
	is_alive = false
	Utils.play_audio(death_audios, "enemy")
	sprite.set_material(null)
	print("DYING!")
	change_state(EVENTS.DIE)
	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "attack":
		enemies_damaged = []
#		change_state(EVENTS.CHASE)
	elif anim_name == "fall":
		change_animation("fall_continue")

func _on_AttackArea2D_body_entered(body):
	if body.is_in_group("human"):
		change_state(EVENTS.ATTACK)
		print("ATTACK BOI")

func change_animation(anim):
	match anim:
		"idle":
			animation.set_speed_scale(0.5)
		"attack":
			animation.set_speed_scale(1.5)			
		"die":
			animation.set_speed_scale(0.7)					
		_:
			animation.set_speed_scale(1)
	animation.play(anim)

func _on_EmotesTimer_timeout():
	hide_all_emotes()
