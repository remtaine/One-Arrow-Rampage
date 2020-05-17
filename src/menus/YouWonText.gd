extends Label

onready var tween = $Tween
onready var main_menu_button = $MainMenuButton
onready var restart_button = $RestartButton

var cm
func _ready():
	cm = modulate
	main_menu_button.disabled = true
	restart_button.disabled = true
		
func appear():
	Utils.has_won = true
	Utils.can_restart = true
	tween.interpolate_property(self, "modulate",modulate, Color(cm.r, cm.g, cm.b, 1.0),1.0, Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.start()
	main_menu_button.disabled = false
	restart_button.disabled = false

func _on_Tween_tween_completed(object, key):
	print("TWEEN DONE ", object, key)
