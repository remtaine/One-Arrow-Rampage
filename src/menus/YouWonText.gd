extends CanvasLayer

onready var tween = $Tween
onready var text = $Text
onready var main_menu_button = $Text/MainMenuButton
onready var restart_button = $Text/RestartButton
onready var next_level_button = $Text/NextLevelButton
onready var thank_you = $Text/ThankYouLabel

var level1_dest = "res://src/levels/Level1.tscn"
var level2_dest = "res://src/levels/Level2.tscn"
var main_menu_dest = "res://src/menus/MainMenu.tscn"

var cm

func _ready():
	cm = text.modulate
	text.modulate = Color(cm.r, cm.g, cm.b, 0.0)
	main_menu_button.disabled = true
	restart_button.disabled = true
	next_level_button.disabled = true

	thank_you.visible = false
		
func appear():
	Utils.has_won = true
	Utils.can_restart = true
	tween.interpolate_property(text, "modulate", text.modulate, Color(cm.r, cm.g, cm.b, 1.0),1.0, Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.start()
	main_menu_button.disabled = false
	restart_button.disabled = false
	if (Utils.current_level_name != "Level2"):
		next_level_button.disabled = false
	else:
		next_level_button.visible = false
		thank_you.visible = true

func _on_RestartButton_pressed():
	restart_button.get_node("AnimationPlayer").play("clicked")
	Utils.reset_scene()

func _on_NextLevelButton_pressed():
	next_level_button.get_node("AnimationPlayer").play("clicked")
	match Utils.current_level_name:
		"Level0":
			next_level_button.get_node("SceneChanger").change_scene(level1_dest)
		"Level1":
			next_level_button.get_node("SceneChanger").change_scene(level2_dest)

func _on_MainMenuButton_pressed():
	main_menu_button.get_node("AnimationPlayer").play("clicked")
	main_menu_button.get_node("SceneChanger").change_scene(main_menu_dest)
