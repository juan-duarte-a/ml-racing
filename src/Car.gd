extends KinematicBody2D
class_name Car

export var speed: int = 100
export var turn_angle: float = 30

var velocity: Vector2
var direction: Vector2
var _vector: int

enum ACTIONS {RUN, STOP, TURN_RIGHT, TURN_LEFT}
var DIRECTIONS: Array = [
	Vector2(0, 1),
	Vector2(-0.5, 0.86602540378),
	Vector2(-0.86602540378, 0.5),
	Vector2(-1, 0),
	Vector2(-0.86602540378, -0.5),
	Vector2(-0.5, -0.86602540378),
	Vector2(0, -1),
	Vector2(0.5, -0.86602540378),
	Vector2(0.86602540378, -0.5),
	Vector2(1, 0),
	Vector2(0.86602540378, 0.5),
	Vector2(0.5, 0.86602540378)
]

# Called when the node enters the scene tree for the first time.
func _ready():
	direction = Vector2(-1, 0)
	velocity = Vector2(0, 0)
	_vector = 3
	set_rotation_degrees(-90)


func set_action(action: int):
	if action == ACTIONS.RUN:
		if velocity == Vector2.ZERO:
			velocity = direction * speed
		else:
			velocity = velocity.normalized() * speed
	elif action == ACTIONS.STOP:
		velocity = Vector2.ZERO
	elif action == ACTIONS.TURN_LEFT:
		if _vector == 0:
			_vector = DIRECTIONS.size() - 1
		else:
			_vector -= 1
		direction = DIRECTIONS[_vector]
		set_rotation_degrees(rotation_degrees - turn_angle)
		if velocity != Vector2.ZERO:
			velocity = direction * speed
	elif action == ACTIONS.TURN_RIGHT:
		if _vector == DIRECTIONS.size() - 1:
			_vector = 0
		else:
			_vector += 1
		direction = DIRECTIONS[_vector]
		set_rotation_degrees(rotation_degrees + turn_angle)
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
