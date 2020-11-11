extends Node2D

var vision_machine_mode: bool
var vision_radar_mode: bool
var vision_center_distance: bool
var vision_front_distance: bool
onready var car: KinematicBody2D = $Car
onready var map_background: TileMap = $TileMapBackground
onready var map_road: TileMap = $TileMapRoad
onready var map_terrain: TileMap = $TileMapTerrain


# Called when the node enters the scene tree for the first time.
func _ready():
	print(scale.length())
	car._speed *= scale.length() / 1.414214
	vision_machine_mode = false
	vision_radar_mode = false
	vision_center_distance = false
	vision_front_distance = false
	for ray in car.radar:
		ray.set_visible(vision_radar_mode)
	car.ray_cast_l.set_visible(vision_center_distance)
	car.ray_cast_r.set_visible(vision_center_distance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("vision_mode"):
		vision_machine_mode = !vision_machine_mode
		map_background.set_visible(!vision_machine_mode)
		map_road.set_visible(!vision_machine_mode)
		map_terrain.set_visible(!vision_machine_mode)
		if vision_machine_mode:
			vision_radar_mode = true
			for ray in car.radar:
				ray.set_visible(vision_radar_mode)
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
