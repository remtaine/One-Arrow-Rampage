extends Node

var last_played_enemy = 0
var last_played_player = 0
var player = null
var camera_screenshake = null
var can_restart = false
var current_level = null
var current_level_name = "none"
var has_won = false

static func get_dir(a1, a2):
	return (a1.global_position - a2.global_position).normalized()

static func get_input_direction(is_human = true, event = Input):
	if is_human:
		return Vector2(
			float(event.is_action_pressed("move_right")) - float(event.is_action_pressed("move_left")),
			0).normalized()
	else:
		return Vector2(-1,0)

func play_audio(val, pitch_type = "none"):
	var pitch	
	var r	
	var s
	
	match pitch_type:
		"enemy":
			last_played_enemy = (last_played_enemy + 1) % val.size()
			r = last_played_enemy
			s = ((randi() % 3) + 2) * 5 #10, 15, 20
			pitch = float(100 + s)/100.0
			print("pitch is ", pitch)
		"player":
			last_played_player = (last_played_player + 1) % val.size()
			r = last_played_player
			s = ((randi() % 2) + 2) * 5 #10, 15
			pitch = float(100 - s)/100.0
			print("pitch is ", pitch)
		_:
			pitch = 0
			randomize()
			r = randi() % val.size()
			
	val[r].set_pitch_scale(pitch)
	val[r].play()

func reset_scene():
	get_tree().reload_current_scene()
	
func freeze_frame(delay = 15):
	OS.delay_msec(delay)
