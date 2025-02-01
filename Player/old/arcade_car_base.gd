extends RigidBody3D

@onready var ground_ray = $CollisionShape3D/RayCast3D

@onready var car_model = $CarModel
@onready var car_mesh = $CarModel/Sketchfab_model/root/CarMesh

@onready var front_left_wheel = $CarModel/Sketchfab_model/root/CarMesh/FrontTires/FrontRightWheel/Wheel
@onready var front_right_wheel =$CarModel/Sketchfab_model/root/CarMesh/FrontTires/FrontLeftWheel/Wheel
@onready var back_left_wheel = $CarModel/Sketchfab_model/root/CarMesh/BackTires/BackLeftWheel/Wheel
@onready var back_right_wheel = $CarModel/Sketchfab_model/root/CarMesh/BackTires/BackRightWheel/Wheel

# Where to place the car mesh relative to the sphere
var sphere_offset = Vector3.DOWN
# Engine power
@export var acceleration = 15.0
# Turn amount, in degrees
@export var steering = 36
@export var drift_steer = 0
# How quickly the car turns
@export var turn_speed = 6.0
# Below this speed, the car doesn't turn
@export var turn_stop_limit = 0.75
# A
@export var max_drif_steer = 27.0

# Variables for input values
var speed_input = 0
var turn_input = 0

func _ready() -> void:
	pass

func _physics_process(delta):
	# Move car model to collision position
	car_model.position = position + sphere_offset
	# Move car ground ray to collision position
	ground_ray.global_position = global_position
	
	if ground_ray.is_colliding():
		if Input.is_action_pressed("ui_accept"):
			drift_steer = -max_drif_steer
		else:
			drift_steer = lerpf(drift_steer, 0, delta * (2 * (1.5-abs(turn_input/deg_to_rad(steering + drift_steer)))))
		
		apply_central_force(car_model.transform.basis.z * speed_input )
	
func _process(delta):
	if not ground_ray.is_colliding():
		print('not colliding')
		return
	speed_input = (Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")) * -acceleration
	turn_input = (Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right"))\
	* deg_to_rad(steering + drift_steer)

	# rotate wheels if moving
	if !is_zero_approx(linear_velocity.z):
		front_left_wheel.rotation.x += delta * linear_velocity.z * acceleration/2 * speed_input
		front_right_wheel.rotation.x += delta  * linear_velocity.z * acceleration/2 * speed_input
		back_left_wheel.rotation.x += delta  * linear_velocity.z * acceleration/2 * speed_input
		back_right_wheel.rotation.x += delta  * linear_velocity.z * acceleration/2 * speed_input
		# Tilt body
		var t = -turn_input / 15
		car_mesh.rotation.z = lerp(car_mesh.rotation.z, t, 10 * delta)
	
	# Rotate wheels for turning
	front_right_wheel.rotation.y = lerpf(front_right_wheel.rotation.y , turn_input, delta * turn_speed)
	front_left_wheel.rotation.y =  lerpf(front_left_wheel.rotation.y , turn_input, delta * turn_speed)
	
	# Rotate car when turning
	if linear_velocity.length() > turn_stop_limit:
		var new_basis = car_model.transform.basis.rotated(car_model.transform.basis.y, turn_input)
		car_model.transform.basis = (car_model.transform.basis).slerp(new_basis,  delta)
		car_model.transform = car_model.transform.orthonormalized()
#
	#var n = ground_ray.get_collision_normal()
	#var xform = align_with_y(car_mesh.global_transform, n)
	#car_mesh.global_transform = car_mesh.global_transform.interpolate_with(xform, 50.0 * delta)

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform.orthonormalized()
