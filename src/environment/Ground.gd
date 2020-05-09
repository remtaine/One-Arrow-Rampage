extends StaticBody2D

var _owner = null
onready var color_displayer = $Sprite/ColorDisplayer
onready var sprite = $Sprite
signal owner_changed

func _ready():
	pass # Replace with function body.

func change_color(new_owner):
	if _owner != null:
		emit_signal("owner_changed", _owner, new_owner)
		_owner.set_territory(-1)
	sprite.self_modulate = new_owner.color
	_owner = new_owner
	new_owner.set_territory(1)
