extends Control

var hp = 3
var hearts = []
var cm = []
onready var player = get_parent().get_parent()
onready var tween = $Tween

func _ready():
	hearts.append($Heart1)	
	hearts.append($Heart2)	
	hearts.append($Heart3)
	for i in range (0,3):
		cm.append(hearts[i].self_modulate)	
	update_health(0)

func update_health(val = -1, all = false):
	if all and not Utils.has_won:
		for i in range (0, 3):
			hearts[i].self_modulate = Color(hearts[i].self_modulate.r, hearts[i].self_modulate.g, hearts[i].self_modulate.b, 0)
	
	elif not Utils.has_won:
		hp += val
		if hp < 3 and hp >= 0:
#			tween.interpolate_property(hearts[hp],"self_modulate", hearts[hp].self_modulate,Color(cm[hp].r * 0.5, cm[hp].g  * 0.5, cm[hp].b * 0.5, 1), 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(hearts[hp],"self_modulate", hearts[hp].self_modulate,Color(cm[hp].r, cm[hp].g, cm[hp].b, 0), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.start()
		if hp == 0:
			player.die()
		
#	match hp:
#		0:
#			hearts[0].visible = false
#			hearts[1].visible = false
#			hearts[2].visible = false
#			player.die()
#		1:
#			hearts[0].visible = true
#			hearts[1].visible = false
#			hearts[2].visible = false
#		2:
#			hearts[0].visible = true
#			hearts[1].visible = true
#			hearts[2].visible = false
#		3:
#			hearts[0].visible = true
#			hearts[1].visible = true
#			hearts[2].visible = true
