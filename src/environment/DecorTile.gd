extends Tiles

class_name DecorTile

func _on_Area2D_body_entered(body):
	if body.is_in_group("characters"):
		change_color(body)
