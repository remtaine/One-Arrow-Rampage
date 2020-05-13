extends Area2D

onready var host = get_parent().get_parent()
var damage
var territory
var enemies_damaged = []

func _ready():
	damage = host.DAMAGE
	territory = host.territory
#	pass # Replace with function body.

func _on_SwordHitbox_area_entered(area):
	territory = host.territory
	if area.is_in_group("weakspots"):# and not enemies_damaged.has(area):
		enemies_damaged.append(area)
		var hit_damage = damage * (territory/20) * area.damage_multiplier
		area.host.hit(hit_damage)
		print("DAMAGED ENEMY BY ", hit_damage)
