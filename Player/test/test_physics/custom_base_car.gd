class_name CustomCar extends RigidBody3D

signal race_ready()

@export var start_position: Vector3
# Car stats resource
@export var car_stat_resource: CarStats

# Custom wheels
@onready var fl_wheel = $FrontRightWheel
@onready var fr_wheel = $FrontLeftWheel
@onready var bl_wheel = $BackLeftWheel
@onready var br_wheel = $BackRightWheel

# Light trails
@onready var right_light_trail: Trail3D = $LightTrailRight/LightTrail
@onready var left_light_trail: Trail3D = $LightTrailLeft/LightTrail

# Speed particles
@onready var speed_particles: GPUParticles3D = $SpeedParticles

# Wheel textures
@onready var fr_wheel_visual = $FrontRightWheel/Wheel
@onready var fl_wheel_visual = $FrontLeftWheel/Wheel
@onready var bl_wheel_visual = $BackLeftWheel/Wheel
@onready var br_wheel_visual = $BackRightWheel/Wheel

# Camera Points
@onready var camera_points = $CameraShowCase

var accel_input: float
var steer_input: float

var fr_visual_start_position: Vector3
var fl_visual_start_position: Vector3
var br_visual_start_position: Vector3
var bl_visual_start_position: Vector3

var use_boost: bool =  false
var speed: float
var normalized_speed: float
var max_speed_particles: int = 30

var can_move: bool = false

enum State {NEUTRAL, DRIVE, DRIFT}

var current_state = State.DRIVE

@onready var neutral_transition_timer: Timer = $NeutralTransitionTimer
@onready var speed_lines_shader: ColorRect = $Control/ColorRect

var max_boost_reserve: float = 10.0
var current_boost_reserve: float
var current_boost_multiplier: float = 1.0
var max_boost_multiplier: float = 2.0
var boost_regen_rate_drive: float = 0.1
var boost_regen_rate_drift: float = 0.2

var boost_consumption_rate: float = 0.5

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

	global_position = start_position
	
	neutral_transition_timer.wait_time = 0.5
	neutral_transition_timer.timeout.connect(_on_neutral_drive_timeout)
	neutral_transition_timer.one_shot = true
	
	current_boost_reserve = max_boost_reserve

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	# Get player inputs
	accel_input = Input.get_action_strength('ui_up') - Input.get_action_strength('ui_down')
	steer_input = Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left')
	
	if accel_input != 0 and current_state == State.NEUTRAL and neutral_transition_timer.is_stopped():
		neutral_transition_timer.start()
	
	if Input.is_action_just_pressed("drift"):
		current_state = State.DRIFT

	if Input.is_action_pressed("boost") and accel_input != 0:
		current_boost_reserve -= boost_consumption_rate
		if current_boost_reserve > 0:
			current_boost_multiplier = max_boost_multiplier
		else:
			current_boost_reserve = 0
			current_boost_multiplier = 1.0

	if Input.is_action_just_released("boost"):
		current_boost_multiplier = 1.0
		
	match current_state:
		State.DRIVE:
			if current_boost_reserve < max_boost_reserve and current_boost_multiplier != max_boost_multiplier:
				current_boost_reserve = clampf(current_boost_reserve + boost_regen_rate_drive, current_boost_reserve, max_boost_reserve)
		_:
			if current_boost_reserve < max_boost_reserve:
				current_boost_reserve = clampf(current_boost_reserve + boost_regen_rate_drift, current_boost_reserve, max_boost_reserve)
	
	print(current_boost_reserve, ' current boost reserve')

	# Update current speed variables
	speed = abs(linear_velocity.dot(transform.basis.z))
	normalized_speed = clampf(speed/car_stat_resource.max_speed, 0.0, 1.0)

	if speed <= 0.3 and current_state == State.DRIVE and accel_input == 0:
		current_state = State.NEUTRAL

	# Control steering
	steering(delta)
	# Update wheel visuals
	wheel_visuals(delta)
	# Apply Speed effects, speed particles and light trails
	speed_visuals()

# Apply traction
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	apply_central_force(-transform.basis.y  * 2000)

# Adjust wheel height and spin based on velocity 
func wheel_visuals(delta) -> void:
	# Move wheel position in accordance to suspension offset
	fr_wheel_visual.position.y = move_toward(fr_wheel_visual.position.y, clampf(fr_visual_start_position.y + fr_wheel.offset, -car_stat_resource.spring_rest_distance, car_stat_resource.spring_rest_distance) , delta)
	fl_wheel_visual.position.y = move_toward(fl_wheel_visual.position.y, clampf(fl_visual_start_position.y + fl_wheel.offset, -car_stat_resource.spring_rest_distance, car_stat_resource.spring_rest_distance) , delta)
	br_wheel_visual.position.y = move_toward(br_wheel_visual.position.y, clampf(br_visual_start_position.y + br_wheel.offset, -car_stat_resource.spring_rest_distance, car_stat_resource.spring_rest_distance) , delta)
	bl_wheel_visual.position.y = move_toward(bl_wheel_visual.position.y, clampf(bl_visual_start_position.y + bl_wheel.offset, -car_stat_resource.spring_rest_distance, car_stat_resource.spring_rest_distance) , delta)
	
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

# Emit speed effects when going x% of max speed
func speed_visuals() -> void:
	if !normalized_speed >= 0.50:
		speed_particles.emitting = false
		# Fade light trail out slowly
		left_light_trail.material_override.albedo_color.a = lerpf(left_light_trail.material_override.albedo_color.a, 0, normalized_speed/20)
		right_light_trail.material_override.albedo_color.a = lerpf(left_light_trail.material_override.albedo_color.a, 0, normalized_speed/20)
		# Hide speed lines
		speed_lines_shader.visible = false
	else:
		speed_particles.amount = max_speed_particles * normalized_speed
		speed_particles.emitting = true
		left_light_trail.emit = true
		right_light_trail.emit = true
		# Fade light trail in slowly :D
		left_light_trail.material_override.albedo_color = Color(car_stat_resource.light_trail_color, lerpf(left_light_trail.material_override.albedo_color.a, 0.01 , normalized_speed/200))
		right_light_trail.material_override.albedo_color = Color(car_stat_resource.light_trail_color, lerpf(right_light_trail.material_override.albedo_color.a, 0.010,  normalized_speed/200))
		# Show speed lines >>>>!
		speed_lines_shader.visible = true

# Return torque value from torque graph
func get_torque(curent_normalized_speed: float) -> float:
	return car_stat_resource.torque_curve.sample(curent_normalized_speed)

# Returns tire grip (between 0,1)
func get_tire_grip(traction: bool = false) -> float:
	if traction:
		return car_stat_resource.front_grip_curve.sample(normalized_speed)
	else:
		return car_stat_resource.rear_grip_curve.sample(normalized_speed)

func _on_neutral_drive_timeout() -> void:
	current_state = State.DRIVE

# Start Race
func start_race() -> void:
	can_move = true
