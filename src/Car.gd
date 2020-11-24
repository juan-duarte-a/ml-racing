extends KinematicBody2D
class_name Car

signal run

enum ACTIONS {RUN, GEAR_UP, GEAR_DOWN, STOP, TURN_RIGHT, TURN_LEFT, CENTER_WHEEL}
enum TURN_MODE {FIXED_ANGLE, USER_CONTROLLED}

const RAD_90: float = 1.5707963 # 90 degrees to radians.

export var high_speed: int = 140
export var low_speed: int = 80
export var gears: int = 2
export var _turn_angle: float = 30 # In degrees.
export var turn_velocity: float  = 20/0.2 # In degrees / sec.
export var max_tire_rotation: float = 30 # Degrees.
export var turning_mode: int = TURN_MODE.FIXED_ANGLE

onready var ray_cast_l: CarRayCast = get_node("RayCasts/CarRayCastL")
onready var ray_cast_r: CarRayCast = get_node("RayCasts/CarRayCastR")
onready var front_position: Area2D = get_node("FrontPositioner")

onready var frt = $Tires/CarTireFR
onready var flt = $Tires/CarTireFL
onready var brt = $Tires/CarTireBR
onready var blt = $Tires/CarTireBL

onready var radar: Array = [
	get_node("RayCasts/CarRayCast1"),
	get_node("RayCasts/CarRayCast2"),
	get_node("RayCasts/CarRayCast3"),
	get_node("RayCasts/CarRayCast4"),
	get_node("RayCasts/CarRayCast5"),
	get_node("RayCasts/CarRayCast6"),
	get_node("RayCasts/CarRayCast7")
]

var _speed: int # In pixels / second.
var speeds: Array
var road: TrackRoad
var velocity: Vector2
var direction: Vector2
var accumulated_angle: float
var turning: bool
var turning_left: bool
var speed_factor: float
var prev_speed_factor: float
var collision_object: KinematicCollision2D
var tires_off_road: int
var accum_tire_rotation_time: float
var temp_vector: Vector2 = Vector2.ZERO
var running: bool
var gear: int
var W: float # Distance between front and back tires.
var centering_wheels: bool
var wheel_tween1: Tween
var wheel_tween2: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	var speed_granularity: int
	
	direction = Vector2(1, 0)
	velocity = Vector2(0, 0)
	turning = false
	running = false
	centering_wheels = false
	accumulated_angle = 0
	speed_factor = 1
	prev_speed_factor = speed_factor
	tires_off_road = 0
	accum_tire_rotation_time = 0
	if get_parent().name != "root":
		road = get_parent().get_node("TrackRoad")
	
	wheel_tween1 = Tween.new()
	add_child(wheel_tween1)
	wheel_tween2 = Tween.new()
	add_child(wheel_tween2)
	
	# warning-ignore:integer_division
	speeds.append(0)
	if gears > 1:
		speed_granularity = (high_speed - low_speed) / (gears - 1)
	else:
		speed_granularity = 0
	for s in range (gears):
		speeds.append(low_speed + speed_granularity * s)
	_speed = speeds[0]
	gear = 0
	
	W = frt.position.distance_to(brt.position)


func set_action(action: int, value: int = -1):
	if action == ACTIONS.RUN:
		if gear == 0:
			gear += 1
			_speed = speeds[gear]
			if velocity == Vector2.ZERO:
				velocity = direction * _speed
				if not running:
					emit_signal("run")
					running = true
	elif action == ACTIONS.STOP:
		velocity = Vector2.ZERO
	elif action == ACTIONS.GEAR_UP:
		if gear < gears:
			gear += 1
			_speed = speeds[gear]
			if velocity == Vector2.ZERO:
				velocity = direction * _speed
				if not running:
					emit_signal("run")
					running = true
			else:
				velocity = velocity.normalized() * _speed
	elif action == ACTIONS.GEAR_DOWN:
		if gear > 0:
			gear -= 1
			_speed = speeds[gear]
			velocity = velocity.normalized() * _speed
		else:
			velocity = Vector2.ZERO
	elif action == ACTIONS.TURN_LEFT:
		if velocity != Vector2.ZERO:
			if turning == false:
				turning = true
				turning_left = true
			elif not turning_left:
				turning = false
#			print("Turning start time: ", OS.get_ticks_msec())
	elif action == ACTIONS.TURN_RIGHT:
		if velocity != Vector2.ZERO:
			if turning == false:
				turning = true
				turning_left = false
			elif turning_left:
				turning = false
#			print("Turning start time: ", OS.get_ticks_msec())
	elif action == ACTIONS.CENTER_WHEEL:
		if velocity != Vector2.ZERO:
			# warning-ignore:return_value_discarded
			wheel_tween1.interpolate_property(frt, "rotation_degrees", null, 90, 0.2, \
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			# warning-ignore:return_value_discarded
			wheel_tween2.interpolate_property(flt, "rotation_degrees", null, 90, 0.2, \
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			# warning-ignore:return_value_discarded
			wheel_tween1.start()
			# warning-ignore:return_value_discarded
			wheel_tween2.start()
			turning = false
#		print("Turning start time: ", OS.get_ticks_msec())


func update_turn_angle(delta: float, left: bool, turn_angle: float = _turn_angle):
	var angle: float
	var rotation_speed: float
	var rotation_time: float
	var tire_rotation_speed: float
	var tire_rotation_speed2: float
	
	if turning_mode == TURN_MODE.FIXED_ANGLE:
#		rotation_speed = abs(_speed / (W / sin(turn_angle)))
#		rotation_time = abs(turn_angle / rad2deg(rotation_speed))
		rotation_speed = deg2rad(turn_velocity) # To radians.
		rotation_time = turn_angle / turn_velocity
		tire_rotation_speed = max_tire_rotation / (rotation_time * 0.7)
		tire_rotation_speed2 = max_tire_rotation / (rotation_time * 0.3)
		
		angle = rotation_speed * delta
		accumulated_angle += angle
		
		accum_tire_rotation_time += delta
		
		if accumulated_angle >= deg2rad(turn_angle):
			angle -= (accumulated_angle - deg2rad(turn_angle))
			accumulated_angle = 0
			turning = false
		
		if left:
			angle *= -1
		direction = direction.rotated(angle)
		velocity = velocity.rotated(angle)
		set_rotation_degrees(rad2deg(rotation + angle))
		
		if accum_tire_rotation_time <= rotation_time * 0.7:
			if left:
	#			print(-tire_rotation_speed * delta)
				rotate_front_tires(-tire_rotation_speed * delta)
			else:
				rotate_front_tires(tire_rotation_speed * delta)
		elif accum_tire_rotation_time <= rotation_time:
			if left:
	#			print(tire_rotation_speed2 * delta)
				rotate_front_tires(tire_rotation_speed2 * delta)
			else:
				rotate_front_tires(-tire_rotation_speed2 * delta)
		
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
			accum_tire_rotation_time = 0 # Reset tire rotation timestamp.
			frt.set_rotation_degrees(90)
			flt.set_rotation_degrees(90)
	#		print(direction)
	#		print("Turning finish time: ", OS.get_ticks_msec())
	elif turning_mode == TURN_MODE.USER_CONTROLLED:
		rotation_speed = abs(_speed / (W / sin(turn_angle)))
		angle = rotation_speed * delta
		accum_tire_rotation_time += delta
		
		if left:
			angle *= -1
		direction = direction.rotated(angle)
		velocity = velocity.rotated(angle)
		set_rotation_degrees(rad2deg(rotation + angle))
		
		# warning-ignore:return_value_discarded
		wheel_tween1.interpolate_property(frt, "rotation_degrees", null, \
				90 + turn_angle if not left else 90 - turn_angle, 0.2, \
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		# warning-ignore:return_value_discarded
		wheel_tween1.start()
		# warning-ignore:return_value_discarded
		wheel_tween2.interpolate_property(flt, "rotation_degrees", null, \
				90 + turn_angle if not left else 90 - turn_angle, 0.2, \
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		# warning-ignore:return_value_discarded
		wheel_tween2.start()


func set_speed(speed: int):
	pass


func get_distance_front() -> int:
	return int((radar[3] as CarRayCast).get_distance())


func get_distance_from_center() -> int:
	# warning-ignore:integer_division
	return int(ray_cast_l.get_distance() - ray_cast_r.get_distance()) / 2


func is_oriented() -> bool:
	if road != null:
		return road.is_oriented(front_position.get_global_position(), direction)
	else:
		return false


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func set_tires_visible(visible_tires: bool):
	frt.set_visible(visible_tires)
	flt.set_visible(visible_tires)
	brt.set_visible(visible_tires)
	blt.set_visible(visible_tires)


func rotate_front_tires(angle: float):
	frt.set_rotation_degrees(frt.get_rotation_degrees() + angle)
	flt.set_rotation_degrees(frt.get_rotation_degrees() + angle)


func update_l_r_raycasts():
	ray_cast_l.force_raycast_update()
	ray_cast_r.force_raycast_update()
	
	if road != null:
		var angle: float = road.angle_to_direction_vector(front_position.get_global_position(), \
				ray_cast_l.get_collision_point() - front_position.get_global_position())
		
		if road.on_road(front_position.get_global_position()) and rad2deg(angle) < 180 and rad2deg(angle) > -180:
			ray_cast_l.set_rotation(ray_cast_l.rotation - (RAD_90 - angle))
			ray_cast_r.set_rotation(ray_cast_r.rotation - (RAD_90 - angle))
	
	ray_cast_l.force_raycast_update()
	ray_cast_r.force_raycast_update()


func reset():
	velocity = Vector2.ZERO
	running = false
	turning = false
	set_position(Vector2(654, 840))
	set_rotation_degrees(180)
	gear = 0
	if road != null:
		direction = road.initial_direction


func _physics_process(delta):
	tires_off_road = int(frt.off_road) + int(flt.off_road) + int(brt.off_road) + int(blt.off_road)
	if tires_off_road > 1:
		speed_factor = 0.6
	else:
		speed_factor = 1
	
	if Input.is_action_just_pressed("forward"):
		print("GEAR UP: ", OS.get_ticks_msec())
		set_action(ACTIONS.GEAR_UP)
	elif Input.is_action_just_pressed("stop"):
		print("GEAR DOWN: ", OS.get_ticks_msec())
		set_action(ACTIONS.GEAR_DOWN)
	elif Input.is_action_just_pressed("turn_left"):
		print("LEFT: ", OS.get_ticks_msec())
		set_action(ACTIONS.TURN_LEFT)
	elif Input.is_action_just_pressed("turn_right"):
		print("RIGHT: ", OS.get_ticks_msec())
		set_action(ACTIONS.TURN_RIGHT)
	elif Input.is_action_just_released("turn_left"):
		print("LEFT: ", OS.get_ticks_msec())
		if turning_mode == TURN_MODE.USER_CONTROLLED:
			set_action(ACTIONS.CENTER_WHEEL)
	elif Input.is_action_just_released("turn_right"):
		print("RIGHT: ", OS.get_ticks_msec())
		if turning_mode == TURN_MODE.USER_CONTROLLED:
			set_action(ACTIONS.CENTER_WHEEL)
	
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
	
	if get_parent().get_name() != "root":
		get_parent().update_corner_vectors()
	update_l_r_raycasts() # This is a must to force distance_to_center raycasts update in time.
	
#	print(ray_cast_l.get_distance() + ray_cast_r.get_distance())
#	print(road.get_track_completion(front_position.get_global_position()))
#	print(road.get_cell_position(front_position.get_global_position()))
#	print("Off road tires: ", tires_off_road)
#	print(road.on_road(front_position.get_global_position()))
#	print(road.is_oriented(front_position.get_global_position(), direction))
#	print(road._get_direction_vector(road.to_local(front_position.get_global_position())))
#	print(radar[3].get_distance())
