extends Label

onready var tween = $Tween
var cm
func _ready():
	cm = modulate
	
func appear():
	Utils.can_restart = true
	tween.interpolate_property(self, "modulate",modulate, Color(cm.r, cm.g, cm.b, 1.0),1.0, Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.start()
