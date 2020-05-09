extends Node2D

func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
