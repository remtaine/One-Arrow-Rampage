extends Label

onready var tween = $Tween
onready var timer = $Timer
export var title = "Level"

const DIST_MOVE = 20
var cm
var fade_duration = 0.5
func _ready():
	cm = self.modulate
	tween.interpolate_property(self, "modulate", modulate, Color(cm.r, cm.g, cm.b, 1.0), fade_duration, Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.interpolate_property(self, "rect_position", rect_position, Vector2(rect_position.x, rect_position.y - DIST_MOVE), fade_duration, Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.start()
	timer.start()

func _on_Timer_timeout():
	tween.interpolate_property(self, "modulate", modulate, Color(cm.r, cm.g, cm.b, 0.0), fade_duration, Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.interpolate_property(self, "rect_position", rect_position, Vector2(rect_position.x, rect_position.y - DIST_MOVE), fade_duration, Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.start()
