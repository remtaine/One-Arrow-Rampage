extends Sprite

var hp = 3
var hearts = []
onready var player = get_parent().get_parent()

func _ready():
	hearts.append($Heart1)	
	hearts.append($Heart2)	
	hearts.append($Heart3)	
	update_health(0)

func update_health(val = -1):
	hp += val
	match hp:
		0:
			player.die()
		1:
			hearts[0].visible = true
			hearts[1].visible = false
			hearts[2].visible = false
		2:
			hearts[0].visible = true
			hearts[1].visible = true
			hearts[2].visible = false
		3:
			hearts[0].visible = true
			hearts[1].visible = true
			hearts[2].visible = true
