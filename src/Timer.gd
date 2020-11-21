extends Timer

var stopwatch_init: int
var stopwatch_temp: int
var state: int
var time: int

enum {STOPPED, PAUSED, RUNNING}
#enum action {START, STOP, RESTART}


func _ready():
	stopwatch_init = 0
	stopwatch_temp = 0
	state = STOPPED


func start_stopwatch():
	if state == STOPPED:
		stopwatch_init = OS.get_ticks_msec()
	elif state == PAUSED:
		stopwatch_init += (OS.get_ticks_msec() - stopwatch_temp)
	state = RUNNING


func stop_stopwatch():
	time = OS.get_ticks_msec() - stopwatch_init
	state = STOPPED


func pause_stopwatch():
	stopwatch_temp = OS.get_ticks_msec()
	time = OS.get_ticks_msec() - stopwatch_init
	state = PAUSED


func restart_stopwatch():
	stopwatch_init = OS.get_ticks_msec()
	stopwatch_temp = stopwatch_init
	time = 0
	state = RUNNING

# Returns current track time as a dictionary of keys: hours, minutes, seconds, milliseconds.
func get_stopwatch_time() -> Dictionary:
	var track_time: Dictionary
	var hours: int  
	var minutes: int
	var seconds: int
	var milliseconds: int
	
	if state == RUNNING:
		time = OS.get_ticks_msec() - stopwatch_init
	
	# warning-ignore:integer_division
	hours = time / 3600000
	# warning-ignore:integer_division
	minutes = (time % 3600000) / 60000
	# warning-ignore:integer_division
	seconds = (time % 3600000) % 60000 / 1000
	milliseconds = (time % 3600000) % 60000 % 1000
	
	track_time = {
		"hours": hours,
		"minutes": minutes,
		"seconds": seconds,
		"milliseconds": milliseconds
	}
	
	return track_time


func get_stopwatch_time_msecs() -> int:
	if state == RUNNING:
		time = OS.get_ticks_msec() - stopwatch_init
	
	return time
