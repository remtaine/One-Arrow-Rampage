extends Line2D

onready var hook = get_parent().get_parent()
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	clear_points()
	add_point(hook.global_position)
	add_point(hook._owner.global_position)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
