extends Node2D

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

onready var car: KinematicBody2D = $Car
onready var map_background: TileMap = $TileMapBackground
onready var map_road: TileMap = $TrackRoad
onready var map_terrain: TileMap = $TileMapTerrain
onready var completion_label: Label = $VBoxContainer/CompletionLabel
#onready var completion_car_sensor: RayCast2D = $Car/FrontPositioner/CompletionRaycast
onready var completion_car_sensor: RayCast2D = $TrackRoad/CompletionCarSensor


# Called when the node enters the scene tree for the first time.
func _ready():
	print(scale.length())
	car.road = map_road
	car._speed *= scale.length() / 1.414214
	vision_machine_mode = false
	vision_radar_mode = false
	vision_center_distance = false
	vision_front_distance = false
	vision_car = true
	vision_tires = false
	vision_oriented = false
	show_center_distance = false
	for ray in car.radar:
#		(ray as CarRayCast).add_exception(get_node("TileMapRoad/RoadCollisionShapes"))
		ray.set_visible(vision_radar_mode)
	car.ray_cast_l.set_visible(vision_center_distance)
	car.ray_cast_r.set_visible(vision_center_distance)
	car.set_tires_visible(false)
	car.direction = Vector2(-1,0)
	get_node("TrackRoad/CornerLines").set_visible(false)


func update_corner_vectors():
	temp_vector1 = map_road.get_cell_position(car.front_position.get_global_position())
	temp_int1 = map_road.road_curves.find(temp_vector1)
	if temp_int1 != -1:
		temp_line1 = map_road.corner_lines[temp_int1]
		temp_line1.points[1] = temp_line1.to_local(car.front_position.get_global_position())


func update_track_completion():
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
	completion_text = str("%.1f" % track_completion) if map_road.on_road(car.front_position.get_global_position()) else "--"
	completion_label.set_text(completion_text + " %")


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
	
	update_track_completion()
