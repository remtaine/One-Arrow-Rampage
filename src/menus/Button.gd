extends Button

export var dest = "res://src/levels/Level0.tscn"

onready var anim = $AnimationPlayer
onready var scene_changer = $SceneChanger
onready var sprite = $AnimatedSprite
onready var tween = $Tween

onready var hover_sound = $HoverSound
onready var unhover_sound = $UnhoverSound
onready var preclick_sound = $PreclickSound

func _ready():
	anim.set_speed_scale(1.0)	
	sprite.play("idle")
	anim.play("idle")	

func _on_Button_pressed():
#	preclick_sound.play()
	anim.set_speed_scale(2.0)
	sprite.play("attack")	
	anim.play("clicked")

func _on_StartButton_mouse_entered():
	pass
#	hover_sound.play()
#	tween.

func _on_StartButton_mouse_exited():
	pass
#	unhover_sound.play()
#	pass # Replace with function body.

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "clicked":
		pass
		
func _on_AnimatedSprite_animation_finished():
	if sprite.get_animation() == "attack":
		scene_changer.change_scene(dest)
	
func _on_AnimatedSprite_frame_changed():
	if sprite.get_animation() == "attack" and sprite.frame == 9:
		$ClickSound.play()
