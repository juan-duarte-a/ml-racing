extends Area2D

var off_road: bool = false
onready var tire = $TireImage

func _on_area_entered(area):
	if area.get_groups().has("road_limit"):
		tire.set_modulate("ee2f2f")
		off_road = true
	else:
		tire.set_modulate("2f3bee")
		off_road = false
