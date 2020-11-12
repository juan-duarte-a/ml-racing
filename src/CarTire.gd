extends Area2D

signal off_road(tire_number)

onready var tire = $TireImage

func _on_area_entered(area):
	if area.get_groups().has("road_limit"):
		tire.set_modulate("ee2f2f")
	else:
		tire.set_modulate("2f3bee")
