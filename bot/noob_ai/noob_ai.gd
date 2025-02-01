extends Node3D

@onready var ray_holder = $RayHolder

@export var num_rays = 8
@export var path: Path3D
@export var path_follow: PathFollow3D

var intrest_array = []
var danger_array = []
var ray_directions = []

func _ready() -> void:
	intrest_array.resize(num_rays)
	danger_array.resize(num_rays)
	ray_directions.resize(num_rays)

	for ray_cast: RayCast3D in ray_holder.get_children():
		var angle = Vector3.ZERO.angle_to(ray_cast.target_position + Vector3.ZERO)
		intrest_array.append(angle)


func _physics_process(delta: float) -> void:
	pass

func set_intrests() -> void:
#	get closes point to position
	var new_path_dir = path.curve.get_closest_point(global_position)
#  get direction to closest point
	var target_direction = global_position.direction_to(new_path_dir)
	for i in num_rays:
		var d = ray_directions[i].rotated(rotation).dot(target_direction)
		intrest_array[i] = max(0, d)
	
	
# Find closes path point from current position, usinng path follow to return forward direction
func get_path_direction(pos):
	var offset = path.curve.get_closest_offset(pos)
	path_follow.h_offset = offset
	return path_follow.transform.basis.x
