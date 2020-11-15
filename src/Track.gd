extends Node2D

var vision_machine_mode: bool
var vision_radar_mode: bool
var vision_center_distance: bool
var vision_front_distance: bool
var vision_car: bool
var vision_tires: bool
var vision_oriented: bool
onready var car: KinematicBody2D = $Car
onready var map_background: TileMap = $TileMapBackground
onready var map_road: TileMap = $TileMapRoad
onready var map_terrain: TileMap = $TileMapTerrain


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
	for ray in car.radar:
#		(ray as CarRayCast).add_exception(get_node("TileMapRoad/RoadCollisionShapes"))
		ray.set_visible(vision_radar_mode)
	car.ray_cast_l.set_visible(vision_center_distance)
	car.ray_cast_r.set_visible(vision_center_distance)
	car.set_tires_visible(false)
	car.direction = Vector2(-1,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("vision_mode"):
		vision_machine_mode = !vision_machine_mode
		map_background.set_visible(!vision_machine_mode)
		map_road.set_visible(!vision_machine_mode)
		map_terrain.set_visible(!vision_machine_mode)
		if vision_machine_mode:
#			vision_radar_mode = true
#			vision_tires = true
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
	elif Input.is_action_just_pressed("center_distance"):
		vision_center_distance = ! vision_center_distance
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
	elif Input.is_action_just_pressed("oriented"):
		vision_oriented = !vision_oriented
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
	
	if vision_tires:
		print("Off road tires: ", car.tires_off_road)
	if vision_front_distance:
		print(car.radar[3].get_distance())
	if vision_center_distance:
		print("From center: ", car.get_distance_to_center(), " -> Oriented :", \
				map_road.is_oriented(car.front_position.get_global_position(), car.direction))
	if vision_oriented:
		print(map_road.is_oriented(car.front_position.get_global_position(), car.direction))

