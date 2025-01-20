extends Node3D

@onready var camera = $Camera3D
@onready var reverse_camera = $ReverseCamera
@export var max_distance = 4

var look_to

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	look_to = get_parent().global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(get_parent().global_position, delta * 20) 
	transform = transform.interpolate_with(get_parent().transform, delta * 5.0)
	look_to = look_to.lerp(get_parent().global_position + get_parent().linear_velocity, delta)
	camera.look_at(look_to)
	reverse_camera.look_at(look_to)
	check_camera_switch()

func check_camera_switch():
	if get_parent().linear_velocity.dot(transform.basis.z) >= -1 or is_zero_approx(get_parent().linear_velocity.dot(transform.basis.z)):
		camera.current = true
	else:
		reverse_camera.current = true
