@tool
extends Node3D

func _process(delta: float) -> void:
	rotation_degrees.y += 1
	if rotation_degrees.y > 360:
		rotation_degrees.y = 0
