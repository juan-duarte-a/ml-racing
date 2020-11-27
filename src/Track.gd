extends Node2D
class_name Track

signal lap_finished(lap_time)
signal lap_stats(lap_time)

var vision_machine_mode: bool
var vision_radar_mode: bool
var vision_center_distance: bool
var vision_front_distance: bool
var vision_car: bool
var vision_tires: bool
var vision_oriented: bool
var show_center_distance: bool
var temp_vector1: Vector2
var temp_line1: Line2D
var temp_int1: int
var track_completion: float
var completion_text: String
var stopwatch_time: Dictionary
var update_timer: bool
var update_completion: bool
var lap_start: bool
var best_lap_time: int
var state_variables: Array
var running: bool

onready var car: KinematicBody2D = $Car
onready var map_background: TileMap = $TileMapBackground
onready var map_road: TileMap = $TrackRoad
onready var map_terrain: TileMap = $TileMapTerrain
onready var completion_label: Label = $VBoxContainer/CompletionLabel
onready var time_label: Label = $VBoxContainer/TimeLabel
onready var completion_car_sensor: RayCast2D = $TrackRoad/CompletionCarSensor
onready var timer: Timer = $Timer
onready var animation_player: AnimationPlayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	var err: int
	
	print(scale.length())
	car.road = map_road
	vision_machine_mode = false
	vision_radar_mode = false
	vision_center_distance = false
	vision_front_distance = false
	vision_car = true
	vision_tires = false
	vision_oriented = false
	show_center_distance = false
	update_timer = true
	update_completion = true
	lap_start = true
	running = false
	best_lap_time = 0
	state_variables = []
	
	for s in range (car.speeds.size()):
		car.speeds[s] *= scale.length() / 1.414214
	
	for ray in car.radar:
#		(ray as CarRayCast).add_exception(get_node("TileMapRoad/RoadCollisionShapes"))
		ray.set_visible(vision_radar_mode)
	car.ray_cast_l.set_visible(vision_center_distance)
	car.ray_cast_r.set_visible(vision_center_distance)
	car.set_tires_visible(false)
	car.direction = Vector2(-1,0)
	get_node("TrackRoad/CornerLines").set_visible(false)
	
	err = car.connect("run", self, "run_start")
	if err != OK:
		print("Error connecting 'run' car signal!")
	err = connect("lap_finished", self, "lap_finished")
	if err != OK:
		print("Error connecting 'lap_finished' signal!")


func update_corner_vectors():
	temp_vector1 = map_road.get_cell_position(car.front_position.get_global_position())
	temp_int1 = map_road.road_curves.find(temp_vector1)
	if temp_int1 != -1:
		temp_line1 = map_road.corner_lines[temp_int1]
		temp_line1.points[1] = temp_line1.to_local(car.front_position.get_global_position())


func update_track_completion(update: bool = true):
	if update:
		completion_text = str("%.1f" % track_completion) if map_road.on_road(car.front_position.get_global_position()) else "--"
		completion_label.set_text(completion_text + " %")


func calculate_track_completion():
	var waypoint_distance: float
	completion_car_sensor.set_position(map_road.to_local(car.front_position.get_global_position()))
	completion_car_sensor.set_cast_to(
		map_road._get_direction_vector(
				map_road.to_local(car.front_position.get_global_position())).normalized() * 200)
	completion_car_sensor.force_raycast_update()
	if map_road.on_road(car.front_position.get_global_position()):
		waypoint_distance = map_road.to_local(car.front_position.get_global_position()).distance_to(
				map_road.to_local(completion_car_sensor.get_collision_point()))
		if waypoint_distance == 0:
			waypoint_distance = 0.000001
	
	track_completion = map_road.get_track_completion(car.front_position.get_global_position())
	track_completion = track_completion + map_road.get_completion_step() * (1 - waypoint_distance / 120.0)


func handle_input_events():
	if Input.is_action_just_pressed("vision_mode"):
		vision_machine_mode = !vision_machine_mode
		map_background.set_visible(!vision_machine_mode)
		map_road.set_visible(!vision_machine_mode)
		map_terrain.set_visible(!vision_machine_mode)
		if vision_machine_mode:
			car.set_tires_visible(true)
			car.ray_cast_l.set_visible(true)
			car.ray_cast_r.set_visible(true)
			for ray in car.radar:
				ray.set_visible(true)
		else:
			car.set_tires_visible(vision_tires)
			for ray in car.radar:
				ray.set_visible(vision_radar_mode)
			car.ray_cast_l.set_visible(vision_center_distance)
			car.ray_cast_r.set_visible(vision_center_distance)
			vision_car = true
			car.get_node("Sprite").set_visible(vision_car)
	elif Input.is_action_just_pressed("radar"):
		vision_radar_mode = !vision_radar_mode
		for ray in car.radar:
			ray.set_visible(vision_radar_mode)
		if vision_front_distance:
			car.radar[3].set_visible(vision_front_distance)
	elif Input.is_action_just_pressed("vision_center_distance"):
		vision_center_distance = ! vision_center_distance
		if vision_center_distance:
			show_center_distance = false
		car.ray_cast_l.set_visible(vision_center_distance)
		car.ray_cast_r.set_visible(vision_center_distance)
	elif Input.is_action_just_pressed("front_distance"):
		vision_front_distance = !vision_front_distance
		car.radar[3].set_visible(vision_front_distance)
		if vision_radar_mode:
			car.radar[3].set_visible(vision_radar_mode)
	elif Input.is_action_just_pressed("car"):
		vision_car = !vision_car
		car.get_node("Sprite").set_visible(vision_car)
	elif Input.is_action_just_pressed("tires"):
		vision_tires = !vision_tires
		car.set_tires_visible(vision_tires)
	elif Input.is_action_just_pressed("vision_oriented"):
		vision_oriented = !vision_oriented
	elif Input.is_action_just_pressed("center_distance"):
		if vision_center_distance:
			show_center_distance = false
		else:
			show_center_distance = !show_center_distance
	elif Input.is_action_just_pressed("vision_off"):
		map_background.set_visible(true)
		map_road.set_visible(true)
		map_terrain.set_visible(true)
		car.get_node("Sprite").set_visible(true)
		car.set_tires_visible(false)
		car.ray_cast_l.set_visible(false)
		car.ray_cast_r.set_visible(false)
		for ray in car.radar:
			ray.set_visible(false)
		vision_machine_mode = false
		vision_radar_mode = false
		vision_center_distance = false
		vision_front_distance = false
		vision_car = true
		vision_tires = false
	elif Input.is_action_just_pressed("reset"):
		car.reset()


func update_time_label(lap_time: bool = false, update: bool = true):
	if update:
		stopwatch_time = timer.get_stopwatch_time()
		# str(stopwatch_time["hours"]) + ":" + 
		var lbl_text: String = str("%0*d" % [2, stopwatch_time["minutes"]]) + ":" + \
				str("%0*d" % [2, stopwatch_time["seconds"]]) + \
				(str(":%0*d" % [2, stopwatch_time["milliseconds"]/10]) if not lap_time \
				else str(":%0*d" % [3, stopwatch_time["milliseconds"]]))
		time_label.set_text(lbl_text)


func update_state():
	state_variables.clear()
	state_variables.append(car.is_oriented())
	state_variables.append(car.get_distance_from_center())
	state_variables.append(car.get_distance_front())
	state_variables.append(stepify(track_completion, 0.001))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	handle_input_events()
	if vision_tires:
		print("Off road tires: ", car.tires_off_road)
	if vision_front_distance:
		print("Front distance: ", car.radar[3].get_distance())
	if vision_center_distance:
		print("From center: ", car.get_distance_from_center())
	if vision_oriented:
		print("Oriented: ", car.is_oriented())
	if show_center_distance:
		print("From center: ", car.get_distance_from_center())
	
	calculate_track_completion()
	update_time_label(false, update_timer)
	update_track_completion(update_completion)
	update_state()


func _on_FinishLine_area_entered(area):
	if area.get_name() == car.front_position.get_name():
		timer.pause_stopwatch()
		var lap_time = timer.get_stopwatch_time_msecs()
		
		if lap_start:
			lap_start = false
			timer.reset_stopwatch()
		else:
			if best_lap_time == 0:
				best_lap_time = lap_time
			else:
				if lap_time < best_lap_time:
					best_lap_time = lap_time
			emit_signal("lap_finished", lap_time)


func run_start():
	timer.start_stopwatch()
	running = true


func reset_track():
	timer.stop_stopwatch()
	timer.reset_stopwatch()
	car.reset()
	running = false


func lap_finished(lap_time):
	print("Lap finished!")
	update_timer = false
	update_completion = false
	update_time_label(true)
	completion_label.text = "100 %"
	animation_player.play("lap_finish")
	emit_signal("lap_stats", lap_time)
	reset_track()
	update_state()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "lap_finish":
		update_timer = true
		update_completion = true
