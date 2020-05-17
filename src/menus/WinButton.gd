extends Button

class_name WinButton

export var dest = "res://src/levels/Level0.tscn"

onready var anim = $AnimationPlayer
onready var scene_changer = $SceneChanger
onready var sprite = $AnimatedSprite
onready var tween = $Tween

func _ready():
	anim.set_speed_scale(1.0)	
#	sprite.play("idle")
#	anim.play("idle")	

func _on_Button_pressed():
	print("I WAS CLICKED")
	anim.set_speed_scale(2.0)
#	sprite.play("attack")	
	anim.play("clicked")

func _on_StartButton_mouse_entered():
	pass
#	tween.

func _on_StartButton_mouse_exited():
	pass # Replace with function body.

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "clicked":
		scene_changer.change_scene(dest)
