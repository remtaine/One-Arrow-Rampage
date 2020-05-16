extends Node

static func get_dir(a1, a2):
	return (a1.global_position - a2.global_position).normalized()

static func get_input_direction(is_human = true, event = Input):
	if is_human:
		return Vector2(
			float(event.is_action_pressed("move_right")) - float(event.is_action_pressed("move_left")),
			0).normalized()
	else:
		return Vector2(-1,0)

func play_audio(val, pitch_type = 0):
	randomize()
	var r = randi() % val.size()
	var pitch
	
	randomize()
	var s = ((randi() % 2) + 2) * 5 #10, 15
	
	match pitch_type:
		"enemy":
			pitch = float(100 + s)/100.0
			print("pitch is ", pitch)
		"player":
			pitch = float(100 - s)/100.0
			print("pitch is ", pitch)
		_:
			pitch = 0
	val[r].set_pitch_scale(pitch)
	val[r].play()

func reset_scene():
	get_tree().reload_current_scene()
