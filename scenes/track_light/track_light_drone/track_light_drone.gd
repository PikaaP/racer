extends Node3D

@onready var light: SpotLight3D = $SpotLight3D

func shine() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(light, 'spot_angle', 17.0, 1)
