class_name CustomCar extends RigidBody3D

@export var start_position: Marker3D
# Car stats resource
@export var car_stat_resource: CarStats

# Custom wheels
@onready var fl_wheel = $FrontRightWheel
@onready var fr_wheel = $FrontLeftWheel
@onready var bl_wheel = $BackLeftWheel
@onready var br_wheel = $BackRightWheel

# Wheel textures
@onready var fr_wheel_visual = $FrontRightWheel/Wheel
@onready var fl_wheel_visual = $FrontLeftWheel/Wheel
@onready var bl_wheel_visual = $BackLeftWheel/Wheel
@onready var br_wheel_visual = $BackRightWheel/Wheel

var accel_input: float
var steer_input: float

var fr_visual_start_position: Vector3
var fl_visual_start_position: Vector3
var br_visual_start_position: Vector3
var bl_visual_start_position: Vector3

var boost
var speed: float
var normalized_speed: float

func _ready() -> void:
	mass = car_stat_resource.mass

	# Set tire variables
	fr_wheel.grip = car_stat_resource.front_grip
	fl_wheel.grip = car_stat_resource.front_grip
	br_wheel.grip = car_stat_resource.rear_grip
	bl_wheel.grip = car_stat_resource.rear_grip
	
	fr_visual_start_position = fr_wheel_visual.position
	fl_visual_start_position = fl_wheel_visual.position
	br_visual_start_position = br_wheel_visual.position
	bl_visual_start_position = bl_wheel_visual.position

	
	global_position = start_position.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	# Get player inputs
	accel_input = Input.get_action_strength('ui_up') - Input.get_action_strength('ui_down')
	steer_input = Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left')

	# Control steering
	steering(delta)
	# Update wheel visuals
	wheel_visuals(delta)

# Apply traction
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	apply_central_force(Vector3.DOWN * 2000)

	speed = abs(state.linear_velocity.dot(transform.basis.z))
	normalized_speed = clampf(speed/car_stat_resource.max_speed, 0.0, 1.0)

# Adjust wheel height and spin based on velocity 
func wheel_visuals(delta) -> void:
	# Move wheel position in accordance to suspension offset
	fr_wheel_visual.position.y = move_toward(fl_wheel_visual.position.y, clampf(fr_visual_start_position.y + fr_wheel.offset, -car_stat_resource.wheel_radius, car_stat_resource.wheel_radius) , delta)
	fl_wheel_visual.position.y = move_toward(fl_wheel_visual.position.y, clampf(fl_visual_start_position.y + fl_wheel.offset, -car_stat_resource.wheel_radius, car_stat_resource.wheel_radius) , delta)
	br_wheel_visual.position.y = move_toward(fl_wheel_visual.position.y, clampf(br_visual_start_position.y + br_wheel.offset, -car_stat_resource.wheel_radius, car_stat_resource.wheel_radius) , delta)
	bl_wheel_visual.position.y = move_toward(fl_wheel_visual.position.y, clampf(bl_visual_start_position.y + bl_wheel.offset, -car_stat_resource.wheel_radius, car_stat_resource.wheel_radius) , delta)
	
	# Find wheel spin direction [-1 || 1]
	var rotation_direction: int
	
	# Spin rear wheels even if not moving but trying to accelerate
	if int(linear_velocity.z) == 0 and accel_input != 0:
		rotation_direction = 1 if accel_input > 0 else -1
		fr_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * delta)
		fl_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * delta)
		br_wheel_visual.rotate_x(rotation_direction * get_torque(normalized_speed) * delta)
		bl_wheel_visual.rotate_x(rotation_direction * get_torque(normalized_speed) * delta)
	else:
		# If moving, spin wheels in direction of forward velocity
		rotation_direction = 1  if linear_velocity.dot(basis.z) > 0 else -1
		
		fr_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * delta)
		fl_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * delta)
		br_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * delta)
		bl_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * delta)
	
# Control steering for front wheels
func steering(delta: float) -> void: 
	var steer_rotation = -steer_input * car_stat_resource.steering_angle * car_stat_resource.steer_limit
	
	if steer_rotation != 0:
		var angle = clamp(fl_wheel.rotation.y + steer_rotation, -car_stat_resource.steering_angle, car_stat_resource.steering_angle)
		var new_rotation = angle * delta
		fl_wheel.rotation.y = move_toward(fl_wheel.rotation.y, new_rotation, car_stat_resource.steer_speed * delta)
		fr_wheel.rotation.y = move_toward(fl_wheel.rotation.y, new_rotation, car_stat_resource.steer_speed * delta)

	else:
		fl_wheel.rotation.y = move_toward(fl_wheel.rotation.y, 0.0, car_stat_resource.steer_speed * delta)
		fr_wheel.rotation.y = move_toward(fl_wheel.rotation.y, 0.0, car_stat_resource.steer_speed * delta)

# Return torque value from torque graph
func get_torque(curent_normalized_speed: float) -> float:
	return car_stat_resource.torque_curve.sample(curent_normalized_speed)

# Returns tire grip (between 0,1)
func get_tire_grip(traction: bool = false) -> float:
	if traction:
		return car_stat_resource.front_grip_curve.sample(normalized_speed)
	else:
		return car_stat_resource.rear_grip_curve.sample(normalized_speed)
