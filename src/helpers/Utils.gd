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
