extends RayCast2D
class_name CarRayCast

var cast_point: Vector2

onready var line: Line2D = $Line2D
onready var cap: Sprite = $Line2D/Triangle

func _ready():
	line.points[1] = Vector2.ZERO


func get_distance() -> float:
	return cast_point.distance_to(Vector2.ZERO)


func _physics_process(_delta):
	cast_point = cast_to
	force_raycast_update()
	
	if is_colliding():
		cast_point = to_local(get_collision_point())
	
	line.points[1] = cast_point
	cap.position = Vector2(cast_point.x - 3, cast_point.y)
	if int(cast_point.distance_to(Vector2.ZERO)) > 1:
		cap.set_visible(true)
		line.set_visible(true)
	else:
		cap.set_visible(false)
		line.set_visible(false)
#	print (int(cast_point.distance_to(Vector2.ZERO)))
