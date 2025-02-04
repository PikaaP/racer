class_name Track extends Node3D

@onready var start_grid = $StartGrid

func add_to_grid(player, index) -> void:
	player.position = start_grid.get_child(index).global_position
	add_child(player)
