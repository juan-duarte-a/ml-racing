extends Node

onready var _server: Node = $Server

# Called when the node enters the scene tree for the first time.
func _ready():
	_server.connect_to_client()
	yield(_server, "connection_to_client")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Server_connection_to_client(status):
	print("Server status: ", status)
	if status == StreamPeerTCP.STATUS_CONNECTED:
		_server.communicate()
