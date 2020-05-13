extends Node2D

class_name Tiles

var new_owner_wr = null
var owner_wr = null
var _owner = null
onready var sprite = $Sprite
signal owner_changed

func _ready():
	pass # Replace with function body.

func change_color(new_owner):
#	var	new_owner_wr = weakref(new_owner)
	var owner_wr = weakref(_owner)
	if owner_wr.get_ref() and _owner != null:
		emit_signal("owner_changed", _owner, new_owner)
		_owner.set_territory(-1)
	sprite.self_modulate = new_owner.color
	_owner = new_owner
	new_owner.set_territory(1)
