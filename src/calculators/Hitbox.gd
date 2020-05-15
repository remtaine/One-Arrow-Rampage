extends Area2D

onready var host = get_parent().get_parent().get_parent()
var damage = 10
var enemies_damaged = []
var hit_damage

export var only_player = false
func _ready():
	if "DAMAGE" in host:
		damage = host.DAMAGE

func _on_SwordHitbox_area_entered(area):
	print("IVE HIT SOMETHING!")
	if area.is_in_group("hurtbox"):# and not enemies_damaged.has(area):
		if not area.enabled:
			return
		if only_player and not area.host.is_in_group("human"): #meaning it only hits player
			return
		if is_in_group("hitbox_enemy") and area.is_in_group("hurtbox_enemy"):
			return
		if is_in_group("hitbox_player") and area.is_in_group("hurtbox_player"):
			return
		enemies_damaged.append(area)
		hit_damage = damage * area.damage_multiplier
		print("Damage calculated as ", hit_damage)
		area.host.hit(hit_damage, area.is_special)

func enable():
	$CollisionShape2D.disabled = false
	
func disable():
	$CollisionShape2D.disabled = true	
