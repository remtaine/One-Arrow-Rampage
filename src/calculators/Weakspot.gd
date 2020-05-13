extends Area2D

onready var host = get_parent().get_parent().get_parent()
export var damage_multiplier = 1.0
var territory
var enemies_damaged = []

func _ready():
	territory = host.territory
#	pass # Replace with function body.

func _on_BackWeakspot_area_entered(area):
	pass
#	territory = host.territory
#	if area.is_in_group("hitboxes"):
#		enemies_damaged.append(area)
#		area.host.hit(damage * (territory/20))
