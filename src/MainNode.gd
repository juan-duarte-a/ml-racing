tool
extends Node

export var comm_test: bool = false
export var time_scale: float = 1.0

var comm_thread: Thread
onready var _server: Server = $Server
onready var c_rect = get_node("HBoxContainer/ColorRect")


# Called when the node enters the scene tree for the first time.
func _ready():
	c_rect.set_position(Vector2(960, 0))
	Engine.set_time_scale(time_scale)
	_server.connect_to_client()
	yield(_server, "connection_to_client")
	print(get_physics_process_delta_time())


func _on_Server_connection_to_client(status):
	comm_thread = Thread.new()
	var err: int
	
	print("Server status: ", status)
	if status == StreamPeerTCP.STATUS_CONNECTED:
		if comm_test:
			err = comm_thread.start(_server, "communicate_test")
		else:
			err = comm_thread.start(_server, "handle_communication", 0.0025 / Engine.get_time_scale())
		
		if err != OK:
			print("Thread failure!")


func _get_configuration_warning() -> String:
	return "Server test mode activated!" if comm_test else ""
