extends TileMap
class_name TrackRoadHD

signal checkpoint(time, num)

const CURVE_VECTOR: int = 100
const MAP_X_SIZE: int = 10
const MAP_Y_SIZE: int = 9
const CAR_INITIAL_X: float = 2710.0
const CAR_INITIAL_Y: float = 3584.0
const CHECKPOINTS: int = 4

var vector_up: Vector2 = Vector2.UP
var vector_down: Vector2 = Vector2.DOWN
var vector_left: Vector2 = Vector2.LEFT
var vector_right: Vector2 = Vector2.RIGHT
var vector_ur: Vector2 = Vector2(1, -1).normalized()
var vector_ul: Vector2 = Vector2(-1, -1).normalized()
var vector_dr: Vector2 = Vector2(1, 1).normalized()
var vector_dl: Vector2 = Vector2(-1, 1).normalized()
var initial_direction: Vector2 = Vector2(-1 ,0)
var checkpoint_check: Array

onready var timer: Timer = get_parent().get_parent().get_parent().get_node("Timer")

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

var completion_matrix: Array = []
var road_cells_positions: Array = [
	Vector2(4, 6),
	Vector2(3, 6),
	Vector2(2, 6),
	Vector2(1, 6),
	Vector2(1, 5),
	Vector2(1, 4),
	Vector2(1, 3),
	Vector2(2, 3),
	Vector2(3, 3),
	Vector2(4, 3),
	Vector2(5, 3),
	Vector2(6, 3),
	Vector2(6, 2),
	Vector2(5, 2),
	Vector2(4, 2),
	Vector2(3, 2),
	Vector2(3, 1),
	Vector2(3, 0),
	Vector2(4, 0),
	Vector2(5, 0),
	Vector2(6, 0),
	Vector2(7, 0),
	Vector2(8, 0),
	Vector2(8, 1),
	Vector2(8, 2),
	Vector2(8, 3),
	Vector2(8, 4),
	Vector2(7, 4),
	Vector2(6, 4),
	Vector2(6, 5),
	Vector2(6, 6),
	Vector2(5, 6)
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

var checkpoints: Array = [
	Vector2(2, 3),
	Vector2(3, 2),
	Vector2(8, 1),
	# Last section to be checked after lap completion
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
	for y_pos in range(MAP_Y_SIZE):
		completion_matrix.append(Array())
		direction_matrix.append(Array())
		for x_pos in range(MAP_X_SIZE):
			if get_cell(x_pos, y_pos) == -1:
				(completion_matrix[y_pos] as Array).append(-1)
				(direction_matrix[y_pos] as Array).append(Vector2.ZERO)
			else:
				(completion_matrix[y_pos] as Array).append(road_cells_positions.find(Vector2(x_pos, y_pos)))
				(direction_matrix[y_pos] as Array).append(direction_road[count])
				count += 1
	print("Done")
	
	for _i in range(CHECKPOINTS - 1):
		checkpoint_check.append(false)


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


func get_completion_step() -> float:
	return 100.0 / float(road_cells_positions.size())


func get_track_completion(position_vector: Vector2) -> float:
	var pos: Vector2
	var percentage: float
	var checkpoint_position: int
	pos = get_cell_position(position_vector)
	checkpoint_position = checkpoints.find(pos)
	if checkpoint_position != -1:
		if not checkpoint_check[checkpoint_position]:
			print("Checkpoint: ", checkpoint_position)
			if checkpoint_position == 0 or checkpoint_check[checkpoint_position - 1] == true:
				checkpoint_check[checkpoint_position] = true
				emit_signal("checkpoint",timer.get_stopwatch_time_msecs(), checkpoint_position)
	percentage = 100.0 * float(completion_matrix[pos.y][pos.x]) / float(road_cells_positions.size())
	
	return percentage if percentage >= 0 else -1.0


func reset_checkpoints():
	checkpoint_check.clear()
	for _c in range(CHECKPOINTS - 1):
		checkpoint_check.append(false)
	print("Checkpoints reset!")
