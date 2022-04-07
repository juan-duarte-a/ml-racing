extends Node2D
class_name TrackHD

signal lap_finished(lap_time)
signal lap_stats(lap_time)
signal update_best_lap_time(lap_time)
signal reset(completion)

const COMPLETION_VECTOR_SIZE = 1200

export var auto_reset: bool = false

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
var time_scale: float
var reseting: bool
var done: bool

onready var viewportrack: ViewportContainer = $ViewportTrack
onready var viewport: Viewport = $ViewportTrack/Viewport
onready var car: CarHD = $ViewportTrack/Viewport/Car
onready var map_background: TileMap = $ViewportTrack/Viewport/TileMapBackground
onready var map_road: TrackRoadHD = $ViewportTrack/Viewport/TrackRoadHD
onready var map_terrain: TileMap = $ViewportTrack/Viewport/TileMapTerrain
onready var road_details: Node2D = $ViewportTrack/Viewport/RoadDetails
onready var completion_label: Label = $UICanvas/VBoxContainer/CompletionLabel
onready var time_label: Label = $UICanvas/VBoxContainer/TimeLabel
onready var completion_car_sensor: RayCast2D = $ViewportTrack/Viewport/TrackRoadHD/CompletionCarSensor
onready var timer: Timer = $Timer
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var help_layer: ColorRect = $HelpCanvasLayer/HelpColorRect


# Called when the node enters the scene tree for the first time.
func _ready():
	var err: int
	help_layer.set_visible(false)
	viewportrack.set_size(Vector2(960, 768))
	viewport.set_size(Vector2(960, 768))
	if get_parent().get_name() == "root":
		OS.set_window_size(Vector2(960, 768))
	
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
	reseting = false
	done = false
	best_lap_time = 0
	state_variables = []
	
	for s in range (car.speeds.size()):
		car.speeds[s] *= scale.length() / 1.414214
	
	for ray in car.radar:
		ray.set_visible(vision_radar_mode)
	car.ray_cast_l.set_visible(vision_center_distance)
	car.ray_cast_r.set_visible(vision_center_distance)
	car.set_tires_visible(false)
	car.direction = Vector2(-1,0)
	
	get_node("ViewportTrack/Viewport/TrackRoadHD/CornerLines").set_visible(false)
	
	err = car.connect("run", self, "run_start")
	if err != OK:
		print("Error connecting 'run' car signal!")
	err = connect("lap_finished", self, "lap_finished")
	if err != OK:
		print("Error connecting 'lap_finished' signal!")
	
	time_scale = Engine.get_time_scale()
	
	set_visible(true)


func update_corner_vectors():
	temp_vector1 = map_road.get_cell_position(car.front_position.get_global_position())
	temp_int1 = map_road.road_curves.find(temp_vector1)
	if temp_int1 != -1:
		temp_line1 = map_road.corner_lines[temp_int1]
		temp_line1.points[1] = temp_line1.to_local(car.front_position.get_global_position())


func update_track_completion(update: bool = true):
	if update:
		completion_text = str("%.1f" % track_completion) if \
				map_road.on_road(car.front_position.get_global_position()) else "--"
		completion_label.set_text(completion_text + " %")


func calculate_track_completion():
	var waypoint_distance: float
	completion_car_sensor.set_position(map_road.to_local(car.front_position.get_global_position()))
	completion_car_sensor.set_cast_to(
		map_road._get_direction_vector(
				map_road.to_local(car.front_position.get_global_position())).normalized() * \
						COMPLETION_VECTOR_SIZE)
	completion_car_sensor.force_raycast_update()
	
	if map_road.on_road(car.front_position.get_global_position()):
		waypoint_distance = map_road.to_local(car.front_position.get_global_position()).distance_to(
				map_road.to_local(completion_car_sensor.get_collision_point()))
		if waypoint_distance == 0:
			waypoint_distance = 0.000001
		track_completion = map_road.get_track_completion(car.front_position.get_global_position())
		track_completion = track_completion + map_road.get_completion_step() * \
				(1 - waypoint_distance / map_road.get_cell_size().x)


func handle_input_events():
	if Input.is_action_just_pressed("vision_mode"):
		vision_machine_mode = !vision_machine_mode
		map_background.set_visible(!vision_machine_mode)
		map_road.set_visible(!vision_machine_mode)
		map_terrain.set_visible(!vision_machine_mode)
		road_details.set_visible(!vision_machine_mode)
		if vision_machine_mode:
			car.set_tires_visible(true)
			car.ray_cast_l.set_visible(true)
			car.ray_cast_r.set_visible(true)
			for ray in car.radar:
				ray.set_visible(true)
			car.get_node("Sprite").set_visible(true)
		else:
			car.set_tires_visible(vision_tires)
			for ray in car.radar:
				ray.set_visible(vision_radar_mode)
			car.ray_cast_l.set_visible(vision_center_distance)
			car.ray_cast_r.set_visible(vision_center_distance)
			car.get_node("Sprite").set_visible(vision_car)
	elif Input.is_action_just_pressed("radar"):
		for ray in car.radar:
			ray.set_visible(!ray.is_visible())
		if vision_front_distance:
			if vision_radar_mode:
				car.radar[3].set_visible(vision_front_distance)
			else:
				car.radar[3].set_visible(true)
		if not vision_machine_mode:
			vision_radar_mode = !vision_radar_mode
	elif Input.is_action_just_pressed("vision_center_distance"):
		if vision_center_distance:
			show_center_distance = false
		car.ray_cast_l.set_visible(!car.ray_cast_l.is_visible())
		car.ray_cast_r.set_visible(!car.ray_cast_r.is_visible())
		if not vision_machine_mode:
			vision_center_distance = !vision_center_distance
	elif Input.is_action_just_pressed("front_distance"):
		if not vision_radar_mode:
			car.radar[3].set_visible(!car.radar[3].is_visible())
		if not vision_machine_mode and not vision_radar_mode:
			vision_front_distance = !vision_front_distance
	elif Input.is_action_just_pressed("car"):
		car.get_node("Sprite").set_visible(!car.get_node("Sprite").is_visible())
		if not vision_machine_mode:
			vision_car = !vision_car
	elif Input.is_action_just_pressed("tires"):
		car.set_tires_visible(!car.frt.is_visible())
		if not vision_machine_mode:
			vision_tires = !vision_tires
	elif Input.is_action_just_pressed("vision_oriented"):
		vision_oriented = !vision_oriented
	elif Input.is_action_just_pressed("vision_off"):
		if help_layer.is_visible():
			help_layer.set_visible(false)
		else:
			map_background.set_visible(true)
			map_road.set_visible(true)
			map_terrain.set_visible(true)
			road_details.set_visible(true)
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
		reset_track(true)
	elif Input.is_action_just_pressed("help"):
		help_layer.set_visible(!help_layer.visible)


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
	if not reseting:
		state_variables.clear()
		state_variables.append(car.is_oriented())
		state_variables.append(car.tires_off_road)
		state_variables.append(car.get_distance_front())
		state_variables.append(car.get_distance_left())
		state_variables.append(car.get_distance_right())
		state_variables.append(car.get_distance_left_30deg())
		state_variables.append(car.get_distance_right_30deg())
		state_variables.append(car.get_distance_left_60deg())
		state_variables.append(car.get_distance_right_60deg())
		state_variables.append(car.get_distance_from_center(true))
		state_variables.append(stepify(track_completion, 0.001))
		state_variables.append(done)
	else:
		reseting = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	handle_input_events()
#	if vision_tires:
#		print("Off road tires: ", car.tires_off_road)
#	if vision_front_distance:
#		print("Front distance: ", car.radar[3].get_distance())
#	if vision_center_distance:
#		print("From center: ", car.get_distance_from_center())
#	if vision_oriented:
#		print("Oriented: ", car.is_oriented())
#	if show_center_distance:
#		print("From center: ", car.get_distance_from_center())
	calculate_track_completion()
	update_time_label(false, update_timer)
	update_track_completion(update_completion)
	if car.ready:
		update_state()
		if auto_reset:
			if state_variables[1] > 2 or \
					not map_road.on_road(car.front_position.get_global_position()):
				reset_track(true)
	else:
		car.ready = true


func run_start():
	timer.start_stopwatch()
	running = true
	done = false


func reset_track(incomplete: bool = false):
	reseting = true
	done = true
	state_variables[1] = 0
	timer.stop_stopwatch()
	timer.reset_stopwatch()
	car.reset()
	running = false
	lap_start = true
	map_road.reset_checkpoints()
	if incomplete:
		emit_signal("reset", track_completion)


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


func _on_FinishLine_area_exited(area):
	if area.get_name() == car.front_position.get_name():
		timer.pause_stopwatch()
		var lap_time = timer.get_stopwatch_time_msecs()
		
		if lap_start:
			lap_start = false
			timer.time_scale = Engine.get_time_scale()
			timer.reset_stopwatch()
			timer.start_stopwatch()
		else:
			if map_road.checkpoint_check.find(false) != -1:
				reset_track(true)
			else:
				if best_lap_time == 0:
					best_lap_time = lap_time
					emit_signal("update_best_lap_time", lap_time)
				else:
					if lap_time < best_lap_time:
						best_lap_time = lap_time
						emit_signal("update_best_lap_time", lap_time)
				emit_signal("lap_finished", lap_time)
