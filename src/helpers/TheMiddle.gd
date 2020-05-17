extends CanvasLayer

onready var pic_handler = $MiddlePicHandler

func _ready():
	for child in pic_handler.get_children():
		child.set_scale(Vector2(0.2,0.2))
