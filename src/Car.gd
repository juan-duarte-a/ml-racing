extends KinematicBody2D
class_name Car

export var speed: int = 100
export var turn_angle: float = 30

var velocity: Vector2
var direction: Vector2

enum ACTIONS {RUN, STOP, TURN_RIGHT, TURN_LEFT}


# Called when the node enters the scene tree for the first time.
func _ready():
	direction = Vector2(-1, 0)
	velocity = Vector2(0, 0)



func set_action(action: int):
	
	if action == ACTIONS.RUN:
		if velocity == Vector2.ZERO:
			velocity = direction * speed
		else:
			velocity = velocity.normalized() * speed
	elif action == ACTIONS.STOP:
		velocity = Vector2.ZERO
	elif action == ACTIONS.TURN_LEFT:
		direction = direction.rotated(deg2rad(-turn_angle))
		set_rotation_degrees(rad2deg(direction.angle()))
		print(direction)
		if velocity != Vector2.ZERO:
			velocity = direction * speed
	elif action == ACTIONS.TURN_RIGHT:
		direction = direction.rotated(deg2rad(turn_angle))
		set_rotation_degrees(rad2deg(direction.angle()))
		print(direction)
		if velocity != Vector2.ZERO:
			velocity = direction * speed


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("forward"):
		print("RUN: ", OS.get_ticks_msec())
		set_action(ACTIONS.RUN)
	elif Input.is_action_just_pressed("stop"):
		print("STOP: ", OS.get_ticks_msec())
		set_action(ACTIONS.STOP)
	elif Input.is_action_just_pressed("turn_left"):
		print("LEFT: ", OS.get_ticks_msec())
		set_action(ACTIONS.TURN_LEFT)
	elif Input.is_action_just_pressed("turn_right"):
		print("RIGHT: ", OS.get_ticks_msec())
		set_action(ACTIONS.TURN_RIGHT)
	
	velocity = move_and_slide(velocity)
