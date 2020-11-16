extends TileMap
class_name TrackRoad

var vector_up: Vector2 = Vector2.UP
var vector_down: Vector2 = Vector2.DOWN
var vector_left: Vector2 = Vector2.LEFT
var vector_right: Vector2 = Vector2.RIGHT
var vector_ur: Vector2 = Vector2(1, -1).normalized()
var vector_ul: Vector2 = Vector2(-1, -1).normalized()
var vector_dr: Vector2 = Vector2(1, 1).normalized()
var vector_dl: Vector2 = Vector2(-1, 1).normalized()

var direction_matrix: Array = []
var direction_road: Array = [
	vector_ur,
	vector_right,
	vector_right,
	vector_right,
	vector_right,
	vector_dr,
	vector_up,
	vector_down,
	vector_ul,
	vector_left,
	vector_left,
	vector_ul,
	vector_down,
	vector_ur,
	vector_right,
	vector_right,
	vector_right,
	vector_right,
	vector_ur,
	vector_down,
	vector_up,
	vector_dl,
	vector_left,
	vector_dl,
	vector_up,
	vector_down,
	vector_ul,
	vector_left,
	vector_left,
	vector_left,
	vector_left,
	vector_dl
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
	var direction_vector: Vector2 = world_to_map(to_local(position_vector))
	return (direction_matrix[direction_vector.y][direction_vector.x] as Vector2).dot(direction) > 0


func _get_direction_vector(position_vector: Vector2) -> Vector2:
	var direction_vector: Vector2 = world_to_map(to_local(position_vector))
	return direction_matrix[direction_vector.y][direction_vector.x]


func angle_to_direction_vector(position_vector: Vector2, vector: Vector2) -> float:
	return vector.angle_to(_get_direction_vector(position_vector))
