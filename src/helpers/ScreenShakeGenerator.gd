extends Node2D

const TRANS = Tween.TRANS_SINE
const EASE = Tween.EASE_IN_OUT

onready var camera = get_parent()
onready var tween = $Tween
onready var frequency = $FrequencyTimer
onready var duration = $DurationTimer

var amplitude = 0
var priority = 0

func start(d = 0.3, f = 15, amplitude = 16, priority = 0):
	if self.priority <= priority:
		self.priority = priority
		self.amplitude = amplitude
		frequency.set_wait_time(1.0/float(f))
		duration.set_wait_time(d)
		
		duration.start()
		frequency.start()
		
		_new_shake()
	
func _new_shake():
	var rand = Vector2()
	randomize()
	rand.x =  rand_range(-amplitude, amplitude)
	rand.y =  rand_range(-amplitude, amplitude)
	change_offset(rand)

func reset():
	change_offset(Vector2.ZERO)
	priority = 0

func change_offset(val):
	tween.interpolate_property(camera, "offset", camera.offset, val, frequency.wait_time, TRANS, EASE)
	tween.start()
	
func _on_FrequencyTimer_timeout():
	_new_shake()

func _on_DurationTimer_timeout():
	reset()
	frequency.stop()
