extends Node2D

var time_start = 0
var time_now = 0

var currently_silent_killed = 0
var currently_killed = 0
var total_enemies_on_map = 0

onready var silent_killed_label = $UI/Goals/SilentKilledLabel
onready var killed_label = $UI/Goals/KilledLabel
onready var time_label = $UI/TimeLabel
onready var won_text = $UI/YouWonText

onready var enemies_handler = $Characters/Enemies

export var level_instance_name = "none"

func _ready():
#	time_start = OS.get_ticks_msec()
	Utils.current_level = self
	Utils.current_level_name = level_instance_name
	print("current level is ", Utils.current_level_name)
	time_start = OS.get_unix_time()
	set_process(true)
	Utils.can_restart = false
	#TODO calculate enemies in Characters/Enemies node
	
	total_enemies_on_map = enemies_handler.get_child_count()
	update_killed_label(0)
	update_silent_killed_label(0)
	
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

	if not Utils.has_won and Utils.player.is_alive:
		time_now = OS.get_unix_time()
		var elapsed = time_now - time_start
		var minutes = elapsed / 60
		var seconds = elapsed % 60
		var str_elapsed = "%02d : %02d" % [minutes, seconds]
	#	print("elapsed : ", str_elapsed)
		time_label.text = str_elapsed
	
	if Input.is_action_just_pressed("reset") and Utils.can_restart:
#	if Input.is_action_just_pressed("reset"):
		Utils.reset_scene()

func hide_instructions():
	if has_node("Instructions"):
		get_node("Instructions").visible = false

func update_silent_killed_label(val = 1):
	currently_silent_killed += val
	silent_killed_label.set_align(Label.ALIGN_CENTER)
	var percent
	if total_enemies_on_map > 0:
		percent = float(currently_silent_killed)/float(total_enemies_on_map)
		percent *= 100
	else:
		percent = 100
	silent_killed_label.text = String(ceil(percent)) + "% Stealth Kills"
#	silent_killed_label.set_align(Label.ALIGN_CENTER)
	
func update_killed_label(val = 1):
	currently_killed += val
#	killed_label.set_align(Label.ALIGN_CENTER)
	killed_label.text = String(currently_killed) + "/" + String(total_enemies_on_map) + " Killed"
#	killed_label.set_align(Label.ALIGN_CENTER)
	
	if currently_killed >= total_enemies_on_map and total_enemies_on_map != 0 and Utils.player.is_alive:
		won_text.appear()
