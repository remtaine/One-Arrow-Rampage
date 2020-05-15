extends Area2D

onready var host = get_parent().get_parent()
export var damage_multiplier = 1.0
export var is_special = false
export var enabled = true
var enemies_damaged = []

func _ready():
	pass # Replace with function body.

func flash(type = "normal"):
	match type:
		"normal":
			pass
		"special":
			pass
	#TODO add specific flashes for each weakpoint

func _on_BackWeakspot_area_entered(area):
	pass
