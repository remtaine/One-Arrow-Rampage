extends Node2D

class_name Trap

const DAMAGE = 10

func _ready():
	$Sprite/Hitboxes/Hitbox/CollisionShape2D.disabled = false
