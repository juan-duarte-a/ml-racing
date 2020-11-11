extends KinematicBody2D
class_name Car

const RAD_90: float = 1.5707963

export var _speed: int = 100 # In pixels / second.
export var _turn_angle: float = 30 # In degrees.
export var turn_velocity: float  = 20/0.2 # In degrees / sec.

onready var road: TileMap = get_parent().get_node("TileMapRoad")
onready var ray_cast_l: CarRayCast = get_node("CarRayCastL")
onready var ray_cast_r: CarRayCast = get_node("CarRayCastR")
onready var front_position: Area2D = get_node("FrontPositioner")

onready var radar: Array = [
	get_node("CarRayCast1"),
	get_node("CarRayCast2"),
	get_node("CarRayCast3"),
	get_node("CarRayCast4"),
	get_node("CarRayCast5"),
	get_node("CarRayCast6"),
	get_node("CarRayCast7")
]

var velocity: Vector2
var direction: Vector2
var accumulated_angle: float
var turning: bool
var turning_left: bool
var speed_factor: float
var prev_speed_factor: float
var collision_object: KinematicCollision2D


enum ACTIONS {RUN, STOP, TURN_RIGHT, TURN_LEFT}


# Called when the node enters the scene tree for the first time.
func _ready():
	direction = Vector2(-1, 0)
	velocity = Vector2(0, 0)
	turning = false
	accumulated_angle = 0
	speed_factor = 1
	prev_speed_factor = speed_factor


func set_action(action: int):
	if action == ACTIONS.RUN:
		if velocity == Vector2.ZERO:
			velocity = direction * _speed
		else:
			velocity = velocity.normalized() * _speed
	elif action == ACTIONS.STOP:
		velocity = Vector2.ZERO
	elif action == ACTIONS.TURN_LEFT:
		if turning == false:
			turning = true
			turning_left = true
#			print("Turning start time: ", OS.get_ticks_msec())
		if velocity != Vector2.ZERO:
			velocity = direction * _speed
	elif action == ACTIONS.TURN_RIGHT:
		if turning == false:
			turning = true
			turning_left = false
#			print("Turning start time: ", OS.get_ticks_msec())
		if velocity != Vector2.ZERO:
			velocity = direction * _speed


func update_turn_angle(delta: float, left: bool, turn_angle: float = _turn_angle):
	var angle: float
	var rotation_speed: float = deg2rad(turn_velocity) # To radians.
	angle = rotation_speed * delta
	accumulated_angle += angle
	
	if accumulated_angle >= deg2rad(turn_angle):
		angle -= (accumulated_angle - deg2rad(turn_angle))
		accumulated_angle = 0
		turning = false
	
	if left:
		angle *= -1
	direction = direction.rotated(angle)
	velocity = velocity.rotated(angle)
	set_rotation_degrees(rad2deg(rotation + angle))
	
	if not turning:
		if abs(direction.angle_to(Vector2.UP)) < deg2rad(0.001):
			direction = Vector2.UP
			if velocity != Vector2.ZERO:
				velocity = Vector2.UP * _speed
			set_rotation_degrees(-90)
		elif abs(direction.angle_to(Vector2.RIGHT)) < deg2rad(0.001):
			direction = Vector2.RIGHT
			if velocity != Vector2.ZERO:
				velocity = Vector2.RIGHT * _speed
			set_rotation_degrees(0)
		elif abs(direction.angle_to(Vector2.DOWN)) < deg2rad(0.001):
			direction = Vector2.DOWN
			if velocity != Vector2.ZERO:
				velocity = Vector2.DOWN * _speed
			set_rotation_degrees(90)
		elif abs(direction.angle_to(Vector2.LEFT)) < deg2rad(0.001):
			direction = Vector2.LEFT
			if velocity != Vector2.ZERO:
				velocity = Vector2.LEFT * _speed
			set_rotation_degrees(180)
#		print(direction)
#		print("Turning finish time: ", OS.get_ticks_msec())


func set_speed(speed: int):
	pass


func get_distance_front() -> int:
	return int((radar[3] as CarRayCast).get_distance())


func get_distance_to_center() -> int:
	ray_cast_l.force_raycast_update()
	ray_cast_r.force_raycast_update()
	
	var angle: float = road.angle_to_direction_vector(front_position.get_global_position(), \
			ray_cast_l.get_collision_point() - front_position.get_global_position())
	
	if road.on_road(front_position.get_global_position()) and rad2deg(angle) < 180 and rad2deg(angle) > -180:
		ray_cast_l.set_rotation(ray_cast_l.rotation - (RAD_90 - angle))
		ray_cast_r.set_rotation(ray_cast_r.rotation - (RAD_90 - angle))
	
	return int(ray_cast_l.get_distance() - ray_cast_r.get_distance())


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _physics_process(delta):
	if not road.on_road(get_global_position()):
		speed_factor = 0.6
	else:
		speed_factor = 1
	
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
	
	if turning:
		update_turn_angle(delta, turning_left)
	
	if prev_speed_factor != speed_factor:
		if speed_factor == 1:
			collision_object = move_and_collide(velocity * delta * (1/prev_speed_factor))
		else:
			collision_object = move_and_collide(velocity * delta * speed_factor)
		prev_speed_factor = speed_factor
	else:
		collision_object = move_and_collide(velocity * delta * speed_factor)
	
	get_distance_to_center()
#	print(road.on_road(front_position.get_global_position()))
#	print(road.is_oriented(front_position.get_global_position(), direction))
#	print(road._get_direction_vector(front_position.get_global_position()))
#	print(radar[3].get_distance())
