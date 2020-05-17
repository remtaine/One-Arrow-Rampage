extends WinButton

var level_dest = {
	"Level0": "res://src/levels/Level0.tscn",
	"Level1": "res://src/levels/Level1.tscn",
	"Level2": "res://src/levels/Level2.tscn"
}

func _ready():
	pass

func _on_NextLevelButton_pressed():
	scene_changer.change_scene(level_dest[Utils.current_level_name])
