extends Area2D

onready var host = get_parent().get_parent().get_parent()
var damage = 10
var enemies_damaged = []
var hit_damage

export var is_trap = false

func _ready():
	if "DAMAGE" in host:
		damage = host.DAMAGE
	
	if is_trap:
		enable()	
	else:
		disable()

#func _on_SwordHitbox_area_entered(area):
#	print("IVE HIT SOMETHING!")
#	if area.is_in_group("hurtbox"):# and not enemies_damaged.has(area):
#		if not area.enabled:
#			return
#		if only_player and not area.host.is_in_group("human"): #meaning it only hits player
#			print("SSORRY, I ONLY HIT PLAYERS")
#			return
#		if is_in_group("hitbox_enemy") and area.is_in_group("hurtbox_enemy"):
#			return
#		if is_in_group("hitbox_player") and area.is_in_group("hurtbox_player"):
#			return
#		enemies_damaged.append(area)
#		hit_damage = damage * area.damage_multiplier
#		print("Damage calculated as ", hit_damage)
#		area.host.hit()

func enable():
	$CollisionShape2D.disabled = false
	
func disable():
	$CollisionShape2D.disabled = true	

func _on_Hitbox_body_entered(body):
	if $CollisionShape2D.disabled:
		return
	if host.is_in_group("human"):
		if body.is_in_group("enemy") and body.is_alive:
			body.hit()
	if host.is_in_group("enemy") or host.is_in_group("traps"):
		if body.is_in_group("human") and body.is_alive:
			if ("is_invulnerable" in body and not body.is_invulnerable):
				body.hit()
			else:
				print ("PLAYER IS INVULNERABLE: ", body.is_invulnerable)
	else:
		print("SOMETHINGS WRONG I CAN FEEL IT")
