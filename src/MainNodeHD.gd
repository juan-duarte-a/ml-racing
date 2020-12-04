tool
extends Node

export var offline_mode: bool = false
export var comm_test: bool = false
export var time_scale: float = 1.0

var comm_thread: Thread
onready var _server: ServerHD = $Server
onready var track: TrackHD = $HBoxContainer/Track
onready var best_lap_label: Label = \
		$HBoxContainer/ColorRect2/VBoxContainer/CenterContainer2/BestLapLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	Engine.set_time_scale(time_scale)
	if not offline_mode:
		_server.connect_to_client()
		yield(_server, "connection_to_client")
	else:
		_server.offline_mode = true
	print(get_physics_process_delta_time())
	if track.connect("update_best_lap_time", self, "update_best_lap_time") != OK:
		print("Error connecting best lap label signal!")


func update_best_lap_time(lap_time: int):
	best_lap_label.set_text(track.get_node("Timer").msecs_to_string(lap_time))


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
