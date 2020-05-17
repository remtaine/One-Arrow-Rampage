extends Button

export var dest = "none"

onready var animation = $AnimationPlayer

func _ready():
	pass

func button_pressed(d = dest):
	animation.play("clicked")	
	$SceneChanger.change_scene(d)
