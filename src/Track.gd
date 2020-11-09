extends Node2D

onready var car: KinematicBody2D = $Car


# Called when the node enters the scene tree for the first time.
func _ready():
	print(scale.length())
	car._speed *= scale.length() / 1.414214


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
