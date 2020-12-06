extends Timer

var stopwatch_init: int
var stopwatch_temp: int
var state: int
var time: int
var time_scale: float

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
	# warning-ignore:narrowing_conversion
	time = (OS.get_ticks_msec() - stopwatch_init) * time_scale
	state = STOPPED


func pause_stopwatch():
	stopwatch_temp = OS.get_ticks_msec()
	# warning-ignore:narrowing_conversion
	time = (OS.get_ticks_msec() - stopwatch_init) * time_scale
	state = PAUSED


func restart_stopwatch():
	stopwatch_init = OS.get_ticks_msec()
	stopwatch_temp = stopwatch_init
	time = 0
	state = RUNNING


func reset_stopwatch():
	time = 0
	stopwatch_init = 0
	stopwatch_temp = 0
	state = STOPPED


# Returns current track time as a dictionary of keys: hours, minutes, seconds, milliseconds.
func get_stopwatch_time() -> Dictionary:
	var track_time: Dictionary
	var hours: int  
	var minutes: int
	var seconds: int
	var milliseconds: int
	
	if state == RUNNING:
	# warning-ignore:narrowing_conversion
		time = (OS.get_ticks_msec() - stopwatch_init) * time_scale
	
	# warning-ignore:integer_division
	hours = time  / 3600000
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


func msecs_to_string(msecs: int) -> String:
	var track_time: String
	var _hours: int  
	var minutes: int
	var seconds: int
	var milliseconds: int
	
	# warning-ignore:integer_division
	_hours = msecs  / 3600000
	# warning-ignore:integer_division
	minutes = (msecs % 3600000) / 60000
	# warning-ignore:integer_division
	seconds = (msecs % 3600000) % 60000 / 1000
	milliseconds = (msecs % 3600000) % 60000 % 1000
	
	track_time = str("%0*d" % [2, minutes]) + ":" + \
				str("%0*d" % [2, seconds]) + \
				str(":%0*d" % [3, milliseconds]) 
	
	return track_time


func get_stopwatch_time_msecs() -> int:
	if state == RUNNING:
	# warning-ignore:narrowing_conversion
		time = (OS.get_ticks_msec() - stopwatch_init) * time_scale
	
	return time
