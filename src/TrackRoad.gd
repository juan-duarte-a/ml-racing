extends TileMap
class_name TrackRoad

const CURVE_VECTOR: int = 100

var vector_up: Vector2 = Vector2.UP
var vector_down: Vector2 = Vector2.DOWN
var vector_left: Vector2 = Vector2.LEFT
var vector_right: Vector2 = Vector2.RIGHT
var vector_ur: Vector2 = Vector2(1, -1).normalized()
var vector_ul: Vector2 = Vector2(-1, -1).normalized()
var vector_dr: Vector2 = Vector2(1, 1).normalized()
var vector_dl: Vector2 = Vector2(-1, 1).normalized()

onready var corner_lines: Array = [
	$CornerLines/LineC1,
	$CornerLines/LineC2,
	$CornerLines/LineC3,
	$CornerLines/LineC3,
	$CornerLines/LineC4,
	$CornerLines/LineC5,
	$CornerLines/LineC6,
	$CornerLines/LineC7,
	$CornerLines/LineC8,
	$CornerLines/LineC9
]

var road_curves: Array = [
	Vector2(1, 6),
	Vector2(1, 3),
	Vector2(6, 3),
	Vector2(6, 2),
	Vector2(3, 2),
	Vector2(3, 0),
	Vector2(8, 0),
	Vector2(8, 4),
	Vector2(6, 4),
	Vector2(6, 6)
]

var direction_matrix: Array = []
var direction_road: Array = [
	Vector2(CURVE_VECTOR, 6), # C5 -> UR
	vector_right,
	vector_right,
	vector_right,
	vector_right,
	Vector2(CURVE_VECTOR, 7), # C6 -> DR
	vector_up,
	vector_down,
	Vector2(CURVE_VECTOR, 5), # C4 -> UL
	vector_left,
	vector_left,
	Vector2(CURVE_VECTOR, 4), # C3 -> UR
	vector_down,
	Vector2(CURVE_VECTOR, 2), # C2 -> UR
	vector_right,
	vector_right,
	vector_right,
	vector_right,
	Vector2(CURVE_VECTOR, 3), # C3 -> UR
	vector_down,
	vector_up,
	Vector2(CURVE_VECTOR, 9), # C8 -> DL
	vector_left,
	Vector2(CURVE_VECTOR, 8), # C7 -> DL
	vector_up,
	vector_down,
	Vector2(CURVE_VECTOR, 1), # C1 -> UL
	vector_left,
	vector_left,
	vector_left,
	vector_left,
	Vector2(CURVE_VECTOR, 10), # 98 -> DL
]


# Called when the node enters the scene tree for the first time.
func _ready():
	var count: int = 0
	for y_pos in range(9):
		direction_matrix.append(Array())
		for x_pos in range(10):
			if get_cell(x_pos, y_pos) == -1:
				(direction_matrix[y_pos] as Array).append(Vector2.ZERO)
			else:
				(direction_matrix[y_pos] as Array).append(direction_road[count])
				count += 1
	print("Done")


func on_road(position_vector: Vector2) -> bool:
	return get_cellv(world_to_map(to_local(position_vector))) != -1


func is_oriented(position_vector: Vector2, direction: Vector2) -> bool:
	var direction_vector: Vector2 = _get_direction_vector(to_local(position_vector))
	return direction_vector.dot(direction) > 0


func angle_to_direction_vector(position_vector: Vector2, vector: Vector2) -> float:
	return vector.angle_to(_get_direction_vector(to_local(position_vector)))


func get_cell_position(position_vector: Vector2) -> Vector2:
	return world_to_map(to_local(position_vector))


func _get_direction_vector(position_vector: Vector2) -> Vector2:
	var curve_line: Line2D
	var dir_vector: Vector2
	var direction_vector: Vector2 = world_to_map(position_vector)
	dir_vector = direction_matrix[direction_vector.y][direction_vector.x]
	
	if dir_vector.x == CURVE_VECTOR:
		curve_line = corner_lines[int(dir_vector.y) - 1]
		return (curve_line.points[1] as Vector2).rotated(deg2rad(90))
	return direction_matrix[direction_vector.y][direction_vector.x]
