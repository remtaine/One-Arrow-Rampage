extends Node2D

var time_start = 0
var time_now = 0
onready var time_label = $UI/TimeLabel
func _ready():
#	time_start = OS.get_ticks_msec()
	time_start = OS.get_unix_time()
	set_process(true)
	
func _process(delta):
#	time_now = OS.get_ticks_msec()
#	var elapsed = time_now - time_start
#	var minutes = elapsed / 60000
#	var seconds = (elapsed % 60000) / 1000
#	var milliseconds = elapsed - (minutes * 60000) - (seconds * 1000)
#	var str_elapsed = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
##	print("elapsed : ", str_elapsed)
#	time_label.text = str_elapsed
#
#	if Input.is_action_just_pressed("reset"):
#		get_tree().reload_current_scene()

	time_now = OS.get_unix_time()
	var elapsed = time_now - time_start
	var minutes = elapsed / 60
	var seconds = elapsed % 60
	var str_elapsed = "%02d : %02d" % [minutes, seconds]
#	print("elapsed : ", str_elapsed)
	time_label.text = str_elapsed
	
	if Input.is_action_just_pressed("reset"):
		Utils.reset_scene()
