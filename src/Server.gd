extends Node
class_name Server

signal connection_to_client(status)
signal action_signal

var _server: TCP_Server
var streamTCP: StreamPeerTCP
var socket_url: String
var port: int
var _online: bool = false
var _byte_array: PoolByteArray
var _data: Array
var _data_action: Array
var comm_flow_control: bool
var manage_action_thread: Thread

const ACTION: int = 65
const REQUEST: int = 82
const ERROR: int = 69

export var packet_size: int = 3 # Byte array size.

""" From ml_comm.py """
#	END = bytearray(bytes([65, 27, 4]))
#	RUN = bytearray(bytes([65, 82, 78]))
#	STOP = bytearray(bytes([65, 83, 84]))
#	TURN_LEFT = bytearray(bytes([65, 84, 76]))
#	TURN_RIGHT = bytearray(bytes([65, 84, 82]))
var ACTIONS = {
	"END": ([ACTION, 27, 4] as PoolByteArray),
	"RUN": ([ACTION, 82, 78] as PoolByteArray),
	"STOP": ([ACTION, 83, 84] as PoolByteArray),
	"TURN_LEFT": ([ACTION, 84, 76] as PoolByteArray),
	"TURN_RIGHT": ([ACTION, 84, 82] as PoolByteArray)
	}

""" From ml_comm.py """
#	CENTER_DISTANCE = bytearray(bytes([82, 67, 68]))
#	IS_ORIENTED = bytearray(bytes([82, 73, 79]))
var REQUESTS = {
	"CENTER_DISTANCE": ([REQUEST, 67, 68] as PoolByteArray),
	"IS_ORIENTED": ([REQUEST, 73, 79] as PoolByteArray)
}

var RESPONSES = {
	"BUSY": ([ERROR, 24, 24] as PoolByteArray)
}

onready var server_timer: Timer = $ServerTimer
onready var server_timer2: Timer = $ServerTimer2
onready var car: Car = get_parent().get_node("Track/Car")


# Called when the node enters the scene tree for the first time.
func _ready():
	var err: int
	
	socket_url = "127.0.0.1"
	port = 11435
	comm_flow_control = false
	manage_action_thread = Thread.new()
	err = manage_action_thread.start(self, "manage_action")
	if err != OK:
		print("Error initializing action manager thread! ", err)


func connect_to_client(port_number: int = port):
	var status: int = -1
	_server = TCP_Server.new()
	
	print("Listening: ", _server.listen(port_number, socket_url))
	
	while true:
		streamTCP = _server.take_connection()
		if streamTCP != null:
			break
		yield(server_timer, "timeout")
		print("Waiting client connection...")
	
	print("StreamTCP: ", streamTCP)
	print("Connected to host: ", streamTCP.is_connected_to_host())
	yield(server_timer, "timeout")
	
	status = streamTCP.get_status()
	_online = true
	emit_signal("connection_to_client", status)


# Handles the communication with the client.
# Should be called as a thread.
# delay: time in seconds before restarting the cycle (time client wait for response, only in action requests)
func handle_communication(delay: float = 0):
	var err: int
	var bytes_available: int
	var temp_int1: int
	
	_data = []
	server_timer.set_one_shot(true)
	
	if err != OK:
		print("Error action manager thread! :", err)
	server_timer2.start(delay)
	
	while _online:
		bytes_available = streamTCP.get_available_bytes()
#		if bytes_available != 0:
#			print(bytes_available)
		if bytes_available >= packet_size:
			if bytes_available > 3:
				print("Bytes: ", bytes_available)
			_data = _receive_data(packet_size) # Gets data sent by client.
			if _data[0] == OK:
				print("Received <- ", _data[0], " ", _data[1][0]," ",_data[1][1]," ",_data[1][2], \
					" ", (_data[1] as PoolByteArray).get_string_from_ascii())
				if _data[1][0] == ACTION:
					if comm_flow_control == true:
						print("Server busy!")
						err = _send_data(RESPONSES["BUSY"])
						if err != OK:
							print("Error sending data to client! :", err)
					else:
						_data_action = [_data.duplicate(true), delay]
						emit_signal("action_signal")
				elif _data[1][0] == REQUEST:
					if (_data[1] as PoolByteArray) == REQUESTS["CENTER_DISTANCE"]:
						temp_int1 = car.get_distance_from_center()
						err = _send_data(int_byte_code(temp_int1))
						print("REQUEST -> Center distance: ", temp_int1, " ", int_byte_code(temp_int1)[1], " ", int_byte_code(temp_int1)[2])
						if err != OK:
							print("Error sending data to client! :", err)
			else:
				print("Error receiving data from client! :", _data[0])
			
			_data.clear()
		yield(server_timer2, "timeout")


func manage_action(_userdata):
	var err: int
	var message: String = ""
	
	yield(self, "connection_to_client")
	
	while _online:
#		err = semaphore.wait()
		yield(self, "action_signal")
		comm_flow_control = true
		if err != OK:
			print("Manage action error! :", err)
		
		var data: Array = _data_action[0]
		
		if data != [] and data[0] == OK:
			if (data[1] as PoolByteArray) == ACTIONS["RUN"]:
				car.set_action(Car.ACTIONS.RUN)
				message = "RUN"
			elif (data[1] as PoolByteArray) == ACTIONS["STOP"]:
				car.set_action(Car.ACTIONS.STOP)
				message = "STOP"
			elif (data[1] as PoolByteArray) == ACTIONS["TURN_LEFT"]:
				car.set_action(Car.ACTIONS.TURN_LEFT)
				message = "TURN_LEFT"
			elif (data[1] as PoolByteArray) == ACTIONS["TURN_RIGHT"]:
				car.set_action(Car.ACTIONS.TURN_RIGHT)
				message = "TURN_RIGHT"
			print("Received <- ", message)
		
		_byte_array = int_byte_code(car.get_distance_front())
		# Sends response to client.
		err = _send_data(_byte_array)
		print("Sent ", _byte_array[0]," ",_byte_array[1]," ",_byte_array[2], " -> ", \
				err, " ", _byte_array.get_string_from_ascii())
		
		if _data_action[1] > 0:
			server_timer.start(_data_action[1])
			yield(server_timer, "timeout") # Waits 'delay' seconds.
		
		comm_flow_control = false


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
	int2 = abs(int_value) - (int1 if int1 < 128 else (int1 - 128)) * 256
	
	return PoolByteArray([0, int1, int2])


# Test communication speed between server and client.
# Should be called as a thread.
func communicate_test(_userdata):
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


func _send_data(byte_array: PoolByteArray) -> int:
	var err = -1
	err = streamTCP.put_data(byte_array)
	
	return err


func _receive_data(bytes: int = 1) -> Array:
	var data: Array = []
	while data.size() == 0 or (data[1] as PoolByteArray).size() == 0:
		data =  streamTCP.get_partial_data(bytes)
	
	return data


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta):
#	pass
