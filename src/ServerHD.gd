extends Node
class_name ServerHD

signal connection_to_client(status)

var offline_mode: bool = false
var _server: TCP_Server
var _output_stream: StreamPeerTCP
var _input_stream: StreamPeerTCP
var socket_url: String
var port1: int
var port2: int
var _online: bool = false
var _byte_array: PoolByteArray
var _data: Array
var _data_action: Array
var update_state: bool
var test: bool
var attemps: int
var update_frames: int

const ACTION: int = 65
const REQUEST: int = 82
const ERROR: int = 69
const BYTE_TRUE: int = 84
const BYTE_FALSE: int = 70
const UPDATE_FRAMES: int = 4

export var packet_size: int = 3 # Byte array size.

""" From ml_comm.py """
#	END = bytearray(bytes([65, 27, 4]))
#	RUN = bytearray(bytes([65, 82, 78]))
#	STOP = bytearray(bytes([65, 83, 84]))
#	GEAR_UP = bytearray(bytes([65, 71, 85]))
#	GEAR_DOWN = bytearray(bytes([65, 71, 68]))
#	TURN_LEFT = bytearray(bytes([65, 84, 76]))
#	TURN_RIGHT = bytearray(bytes([65, 84, 82]))
#	CENTER_WHEEL = bytearray(bytes([65, 67, 87]))

var ACTIONS = {
	"END": ([ACTION, 27, 4] as PoolByteArray),
	"RUN": ([ACTION, 82, 78] as PoolByteArray),
	"STOP": ([ACTION, 83, 84] as PoolByteArray),
	"GEAR_UP": ([ACTION, 71, 85] as PoolByteArray),
	"GEAR_DOWN": ([ACTION, 71, 68] as PoolByteArray),
	"TURN_LEFT": ([ACTION, 84, 76] as PoolByteArray),
	"TURN_RIGHT": ([ACTION, 84, 82] as PoolByteArray),
	"CENTER_WHEEL": ([ACTION, 67, 87] as PoolByteArray),
	}

""" From ml_comm.py """
#	CENTER_DISTANCE = bytearray(bytes([82, 67, 68]))
#	IS_ORIENTED = bytearray(bytes([82, 73, 79]))
var REQUESTS = {
	"CENTER_DISTANCE": ([REQUEST, 67, 68] as PoolByteArray),
	"IS_ORIENTED": ([REQUEST, 73, 79] as PoolByteArray),
	"LAP_TIME": ([76, 84] as PoolByteArray)
}

var RESPONSES = {
	"BUSY": ([ERROR, 24, 24] as PoolByteArray),
	"CONNECTION_OK": ([67, 79, 75] as PoolByteArray)
}

onready var server_timer: Timer = $ServerTimer
onready var car: CarHD = get_parent().get_node("HBoxContainer/Track/ViewportTrack/Viewport/Car")
onready var track: TrackHD = get_parent().get_node("HBoxContainer/Track")
onready var attemps_lbl = get_parent().get_node(
			"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer3/GridContainer/AttempsLabel")
onready var is_oriented_lbl = get_parent().get_node(
			"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer5/GridContainer/Label1-2")
onready var off_road_tires_lbl = get_parent().get_node(
			"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer5/GridContainer/Label2-2")
onready var front_distance_lbl = get_parent().get_node(
			"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer5/GridContainer/Label3-2")
onready var center_distance_lbl = get_parent().get_node(
			"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer5/GridContainer/Label4-2")


# Called when the node enters the scene tree for the first time.
func _ready():
	socket_url = "127.0.0.1"
	port1 = 11435
	port2 = 11436
	update_state = false
	test = false
	attemps = 0
	update_frames = 1
	
	if track.connect("lap_stats", self, "send_lap_stats") != OK:
		print("Error connecting 'lap_stats' signal!")
	if track.connect("reset", self, "reset") != OK:
		print("Error connecting 'reset' signal!")


func connect_to_client(port_number1: int = port1, port_number2: int = port2):
	var err: int
	var status: int = -1
	_server = TCP_Server.new()
	_output_stream = StreamPeerTCP.new()
	
	print("Listening: ", _server.listen(port_number1, socket_url))
	
	while true:
		_input_stream = _server.take_connection()
		if _input_stream != null:
			break
		yield(server_timer, "timeout")
		print("Waiting client connection...")
	
	print("StreamTCP: ", _input_stream)
	print("Connected to host: ", _input_stream.is_connected_to_host())
	_input_stream.set_no_delay(true)
	status = _input_stream.get_status()
	
	while _input_stream.get_available_bytes() <= packet_size:
		_data = _input_stream.get_partial_data(packet_size) # Gets data sent by client.
		if _data[0] == OK and (_data[1] as PoolByteArray) == RESPONSES["CONNECTION_OK"]:
			err = _send_data(RESPONSES["CONNECTION_OK"])
			if err != OK:
				print("Error with 'input' connection!")
			print("'Input' connection established.")
			break
			yield(server_timer, "timeout")
	
		print("Waiting client confirmation...")
		yield(server_timer, "timeout")
	
	err = _output_stream.connect_to_host(socket_url, port_number2)
	if err != OK:
		print("'Output' connection error!")
	else:
		err = _output_stream.put_data(RESPONSES["CONNECTION_OK"])
		if err != OK:
			print("Error sending data through 'output' connection!")
		else:
			print("'Output' connection established.")
	
	_online = true
	emit_signal("connection_to_client", status)


# Handles the communication with the client.
# Should be called as a thread.
# delay: time in seconds before restarting the cycle (time client wait for response, only in action requests)
func handle_communication(delay: float = 0):
	var bytes_available: int
	
	_data = []
	server_timer.start(delay)
	
	while _online:
		bytes_available = _input_stream.get_available_bytes()
		if bytes_available >= packet_size:
			_data = _receive_data(packet_size) # Gets data sent by client.
			if _data[0] == OK:
				print("Received <- ", _data[0], " ", _data[1][0]," ",_data[1][1]," ",_data[1][2], \
					" ", (_data[1] as PoolByteArray).get_string_from_ascii())
				if _data[1][0] == ACTION:
					_data_action = [_data.duplicate(true), delay]
					manage_action()
			else:
				print("Error receiving data from client! :", _data[0])
			
			_data.clear()
		yield(server_timer, "timeout")


# Manages action requests from client.
# This method should be call as a thread.
func manage_action():
	var message: String = ""
	var data: Array = _data_action[0]
	
	if data != [] and data[0] == OK:
		if (data[1] as PoolByteArray) == ACTIONS["RUN"]:
			car.set_action(Car.ACTIONS.RUN)
			message = "RUN"
		elif (data[1] as PoolByteArray) == ACTIONS["STOP"]:
			car.set_action(Car.ACTIONS.STOP)
			message = "STOP"
		elif (data[1] as PoolByteArray) == ACTIONS["GEAR_UP"]:
			car.set_action(Car.ACTIONS.GEAR_UP)
			message = "GEAR_UP"
		elif (data[1] as PoolByteArray) == ACTIONS["GEAR_DOWN"]:
			car.set_action(Car.ACTIONS.GEAR_DOWN)
			message = "GEAR_DOWN"
		elif (data[1] as PoolByteArray) == ACTIONS["TURN_LEFT"]:
			car.set_action(Car.ACTIONS.TURN_LEFT)
			message = "TURN_LEFT"
		elif (data[1] as PoolByteArray) == ACTIONS["TURN_RIGHT"]:
			car.set_action(Car.ACTIONS.TURN_RIGHT)
			message = "TURN_RIGHT"
		elif (data[1] as PoolByteArray) == ACTIONS["CENTER_WHEEL"]:
			car.set_action(Car.ACTIONS.CENTER_WHEEL)
			message = "CENTER_WHEEL"
		print("Received traduction <- ", message)


func byte_int_decode(byte_array: PoolByteArray) -> int:
	# warning-ignore:integer_division
	if int(byte_array[1] / 128) == 0:
		return -1 * (byte_array[1] * 256 + byte_array[2])
	else:
		return (byte_array[1] - 128) * 256 + byte_array[2]


func int_byte_code(int_value: int) -> PoolByteArray:
	var int1: int
	var int2: int
	
	int1 = int(abs(int_value) / 256)
	if int_value > 0:
		int1 += 128
	# warning-ignore:narrowing_conversion
	int2 = abs(int_value) - (int1 if int1 < 128 else (int1 - 128)) * 256
	
	return PoolByteArray([0, int1, int2])


func byte_bool_decode(byte_array: PoolByteArray) -> bool:
	return true if byte_array[2] == BYTE_TRUE else false


func bool_byte_code(boolean: bool) -> PoolByteArray:
	return PoolByteArray([0, 0, BYTE_TRUE if boolean else BYTE_FALSE])


# Test communication speed between server and client.
# Should be called as a thread.
func communicate_test(_userdata):
	test = true
	var time_start: bool = false
	var time_before: float
	var total_time: float
	var data: Array
	var count: int = 0
	var byte_array: PoolByteArray
	var online: bool
	
	var rnd: RandomNumberGenerator = RandomNumberGenerator.new()
	rnd.randomize()
	
	online = true
	
	while online:
		data = _receive_data(3) # Waits for data to be delivered from client.
		print("Received #", count, " <- ", data[0], " ", data[1][0],data[1][1],data[1][2], " ", \
				(data[1] as PoolByteArray).get_string_from_ascii())

		if time_start == false:
			time_before = OS.get_ticks_msec()
			time_start = true
		
		count += 1
		byte_array = [rnd.randi_range(32, 126), rnd.randi_range(32, 126), rnd.randi_range(32, 126)]
		print("Sent ", byte_array[0],byte_array[1],byte_array[2], " -> ", \
				_send_data(byte_array), " ", byte_array.get_string_from_ascii()) # Sends response to client.
		
		if (data[1] as PoolByteArray) == ACTIONS["END"]:
			online = false
	
	total_time = OS.get_ticks_msec() - time_before
	print("Total time (sec): ", total_time / 1000.0)
	print("Messages per second: ", count / (total_time / 1000.0))


func send_state_variables():
	var err: int
	var state_parameters: String = ""
	
	if not test:
		for s in track.state_variables:
			state_parameters += str(s) + ":"
		state_parameters = state_parameters.left(len(state_parameters) - 1)
		err = _output_stream.put_data(PoolByteArray([len(state_parameters)]))
		err = _output_stream.put_data(state_parameters.to_ascii())
		if err != OK:
			print("Error sending state data through 'output' connection!")


func send_lap_stats(lap_time: int):
	get_parent().checkpoint(lap_time, track.map_road.checkpoints.size())
	reset(100)
	
	if not offline_mode:
		var err: int
		var lap_data: PoolByteArray = REQUESTS["LAP_TIME"]
		
		lap_data.append_array(str(lap_time).to_ascii())
		print(lap_data.get_string_from_ascii())
		err = _output_stream.put_data([lap_data.size()])
		err = _output_stream.put_data(lap_data)
		if err != OK:
			print("Error sending lap stats!")


func reset(track_completion: float):
	attemps += 1
	attemps_lbl.set_text(str(attemps))
	get_parent().reset_checkpoints()
	get_parent().update_average_completion(track_completion)


func _send_data(byte_array: PoolByteArray) -> int:
	var err = -1
	err = _input_stream.put_data(byte_array)
	
	return err


func _receive_data(bytes: int = 3) -> Array:
	var data: Array = []
	while data.size() == 0 or (data[1] as PoolByteArray).size() == 0:
		data =  _input_stream.get_partial_data(bytes)
	
	return data


func _update_state_labels():
	var temp_str: String
	if track.state_variables[0]:
		temp_str = "Sí"
	else:
		temp_str = "No"
	is_oriented_lbl.set_text(temp_str)
	off_road_tires_lbl.set_text(str(track.state_variables[1]))
	front_distance_lbl.set_text(str(track.state_variables[2]))
	center_distance_lbl.set_text(str(track.state_variables[3]))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if _online:
		send_state_variables()
	if update_frames == UPDATE_FRAMES:
		update_frames = 1
		_update_state_labels()
	else:
		update_frames += 1
