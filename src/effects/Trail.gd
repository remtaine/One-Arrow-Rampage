extends Line2D

onready var hook = get_parent().get_parent()
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	clear_points()
	add_point(hook.global_position)
	add_point(hook._owner.get_node("CenterPivot").global_position)
	
func get_dir():
	"""
		returns direction between hook and player
	"""
	return
