extends Node

signal connection_to_client(status)

var _server: TCP_Server
var streamTCP: StreamPeerTCP
var socket_url: String
var port: int

var ACTIONS = {"END": ([27, 27, 27] as PoolByteArray)}

var online: bool

onready var server_timer: Timer = $ServerTimer


# Called when the node enters the scene tree for the first time.
func _ready():
	socket_url = "127.0.0.1"
	port = 11435


func connect_to_client():
	var status: int = -1
	_server = TCP_Server.new()
	
	print("Listening: ", _server.listen(port, socket_url))
	
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
	emit_signal("connection_to_client", status)


func communicate():
	var time_start: bool = false
	var time_before: float
	var total_time: float
	var data: Array
	var count: int = 0
	var byte_array: PoolByteArray
	
	var rnd: RandomNumberGenerator = RandomNumberGenerator.new()
	rnd.randomize()
	
	online = true
	
	while online:
		data = receive_data(3) # Waits for data to be delivered from client.
		print("Received #", count, " <- ", data[0], " ", data[1][0],data[1][1],data[1][2], " ", (data[1] as PoolByteArray).get_string_from_ascii())

		if time_start == false:
			time_before = OS.get_ticks_msec()
			time_start = true
		
		if (data[1] as PoolByteArray) == ACTIONS["END"]:
			break
		
		count += 1
		byte_array = [rnd.randi_range(32, 126), rnd.randi_range(32, 126), rnd.randi_range(32, 126)]
		print("Sent ", byte_array[0],byte_array[1],byte_array[2], " -> ", send_data(byte_array), " ", byte_array.get_string_from_ascii()) # Sends response to client.
	
	total_time = OS.get_ticks_msec() - time_before
	print("Total time (sec): ", total_time / 1000.0)
	print("Messages per second: ", count / (total_time / 1000.0))


func send_data(byte_array: PoolByteArray) -> int:
	var err = -1
	err = streamTCP.put_data(byte_array)
	
	return err


func receive_data(bytes: int = 1) -> Array:
	var data: Array = []
	while data.size() == 0 or (data[1] as PoolByteArray).size() == 0:
		data =  streamTCP.get_data(bytes)
	
	return data


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
