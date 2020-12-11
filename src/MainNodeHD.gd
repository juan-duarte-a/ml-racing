tool
extends Node

export var offline_mode: bool = false
export var comm_test: bool = false
export var time_scale: float = 1.0

var comm_thread: Thread
var checkpoints_time: Array
var accumulated_checkpoint_time: int
var best_checkpoints_time: Array
var average_completion: float

onready var cp_timer: Timer = $CheckPointsTimer
onready var _server: ServerHD = $Server
onready var track: TrackHD = $HBoxContainer/Track
onready var best_lap_label: Label = \
		$HBoxContainer/ColorRect2/VBoxContainer/CenterContainer2/BestLapLabel
onready var avg_completion_label: Label = \
		$HBoxContainer/ColorRect2/VBoxContainer/CenterContainer6/HBoxContainer/AvgCompletedLabel

onready var checkpoint_labels: Array = [
	$"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer4/CheckpointsLabels/Label1-2",
	$"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer4/CheckpointsLabels/Label2-2",
	$"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer4/CheckpointsLabels/Label3-2",
	$"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer4/CheckpointsLabels/Label4-2"
]

onready var best_checkpoint_labels: Array = [
	$"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer4/CheckpointsLabels/Label1-3",
	$"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer4/CheckpointsLabels/Label2-3",
	$"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer4/CheckpointsLabels/Label3-3",
	$"HBoxContainer/ColorRect2/VBoxContainer/CenterContainer4/CheckpointsLabels/Label4-3"
]


# Called when the node enters the scene tree for the first time.
func _ready():
	Engine.set_time_scale(time_scale)
	checkpoints_time = Array()
	best_checkpoints_time = Array()
	accumulated_checkpoint_time = 0
	average_completion = 0.0
	
	for _i in range(checkpoint_labels.size()):
		best_checkpoints_time.append(-1)
	
	if not offline_mode:
		_server.connect_to_client()
		yield(_server, "connection_to_client")
	else:
		_server.offline_mode = true
	print(get_physics_process_delta_time())
	if track.connect("update_best_lap_time", self, "update_best_lap_time") != OK:
		print("Error connecting best lap label signal!")
	if track.map_road.connect("checkpoint", self, "checkpoint") != OK:
		print("Error connecting best lap label signal!")
	if cp_timer.connect("timeout", self, "checkpoint_timer_signal") != OK:
		print("Error connecting checkpoint timer signal!")


func update_best_lap_time(lap_time: int):
	best_lap_label.set_text(track.get_node("Timer").msecs_to_string(lap_time))


func checkpoint(time, pos: int):
	var time_delta: int
	
	time_delta = time
	if pos != 0:
		time_delta -= accumulated_checkpoint_time
	(checkpoint_labels[pos] as Label).set_text(track.get_node("Timer").msecs_to_string(time_delta))
	checkpoints_time.append(time_delta)
	if _server.attemps == 0 or checkpoints_time[checkpoints_time.size() - 1] < \
			best_checkpoints_time[checkpoints_time.size() - 1] or \
			best_checkpoints_time[checkpoints_time.size() - 1] == -1:
		best_checkpoints_time[checkpoints_time.size() - 1] = checkpoints_time[checkpoints_time.size() - 1]
		(checkpoint_labels[pos] as Label).set_modulate("61f563")
	else:
		(checkpoint_labels[pos] as Label).set_modulate("fc6464")
	if pos == checkpoint_labels.size() - 1:
		accumulated_checkpoint_time = 0
	else:
		accumulated_checkpoint_time += time_delta


func reset_checkpoints():
	checkpoints_time.clear()
	accumulated_checkpoint_time = 0
	update_best_checkpoints()
	cp_timer.start()


func checkpoint_timer_signal():
	for i in range(checkpoint_labels.size()):
		if checkpoints_time.size() > 0 and i < checkpoints_time.size():
			(checkpoint_labels[i] as Label).set_text(
					track.get_node("Timer").msecs_to_string(checkpoints_time[i]))
		else:
			(checkpoint_labels[i] as Label).set_text("--:--:---")
		for l in checkpoint_labels:
			(l as Label).set_modulate("ffffff")


func update_best_checkpoints():
	for i in range(best_checkpoints_time.size()):
		if best_checkpoints_time[i] != -1:
			(best_checkpoint_labels[i] as Label).set_text(
					track.get_node("Timer").msecs_to_string(best_checkpoints_time[i]))


func update_average_completion(track_completion: float):
	average_completion = (average_completion * (_server.attemps - 1) + track_completion) / _server.attemps
	avg_completion_label.set_text(str("%.1f" % average_completion) + " %")


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
