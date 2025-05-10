class_name CustomCar extends RigidBody3D

# Race ready signal, emited by camera when showcase is over
signal race_ready()
# Race over signal, 0 laps remaining
signal race_over(car)

signal start_boost()
signal stop_boost()


# Grid start position (global coordinates)
@export var start_position: Vector3
@export var start_direction: Vector3

# Checkpoint status and lap tracking
# Checkpoint refernce for all checkpoints returned by Track class
@export var checkpoint_array = []
# Current checkpoint index value
@export var current_checkpoint: int = 0
# Next checkpoint
@export var target_checkpoint: int = 1
# Distance to checkpoint
var distance_to_checkpoint: float
# Current lap
@export var current_lap: int = 1
# Max laps in race, passed by Track
@export var max_lap_count: int
# Path reference from current Track
@export var path: Path3D
# Path points refernce from baked path curve
var points: PackedVector3Array

# Car stats resource
@export var car_stat_resource: CarStats

# Custom wheels
@onready var fr_wheel = $FrontRightWheel
@onready var fl_wheel = $FrontLeftWheel
@onready var br_wheel = $BackRightWheel
@onready var bl_wheel = $BackLeftWheel

# Break lights
@onready var break_light_holder: Node3D = $BreakLightHolder
# Light trails
@onready var right_light_trail: Trail3D = $LightTrailRight/LightTrail
@onready var left_light_trail: Trail3D = $LightTrailLeft/LightTrail

# Speed effects
# Speed particles
@onready var speed_particles: GPUParticles3D = $SpeedParticles
# Speed lines (overlay)
@onready var speed_lines_shader: ColorRect = $Control/ColorRect


# Wheel textures
@onready var fr_wheel_visual = $FrontRightWheel/Wheel
@onready var fl_wheel_visual = $FrontLeftWheel/Wheel
@onready var bl_wheel_visual = $BackLeftWheel/Wheel
@onready var br_wheel_visual = $BackRightWheel/Wheel

var fr_visual_start_position: Vector3
var fl_visual_start_position: Vector3
var br_visual_start_position: Vector3
var bl_visual_start_position: Vector3

# Camera Points
@onready var camera_points = $CameraShowCase

@onready var engine: CarEngine = $Engine
@onready var exhaust = $ExhaustHolder/Exhaust

# Car function variables
var accel_input: float
var steer_input: float
var speed: float
var normalized_speed: float
var max_speed_particles: int = 30

# State machine
# Track response State machine, controlled by current track
enum RaceState {START, RACE, FINISH}
# Car function state
enum State {NEUTRAL, DRIVE, DRIFT, DISABLED}

# Starting states
var current_state: State = State.NEUTRAL
var current_race_state = RaceState.START

# Timers
# Timer to remove neutral torque boost when moving from State.NEUTRAL to State,DRIVE
@onready var neutral_transition_timer: Timer = $NeutralTransitionTimer
# Respawn timer to re-enable PlayerCar and Bot collisions
@onready var respawn_timer: Timer = $RespawnTimer


func _ready() -> void:
	#lock_rotation = true
	axis_lock_angular_y = true
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
	look_at(start_direction, global_basis.y)
	
	# Timer properites
	neutral_transition_timer.wait_time = 0.5
	neutral_transition_timer.timeout.connect(_on_neutral_drive_timeout)
	neutral_transition_timer.one_shot = true
	
	points = path.curve.get_baked_points()
	
	respawn_timer.timeout.connect(_handle_respawn)
	
	# Setup Engine
	engine.emit_exaust.connect(_handle_exaust_emmision)


func _process(delta: float) -> void:
	distance_to_checkpoint = global_position.distance_to(checkpoint_array[target_checkpoint].global_position)

# Signal engine to consume boost
func apply_boost() -> void:
	start_boost.emit()

# Control steering for front wheels
func steering(delta: float) -> void: 
	var steer_rotation = steer_input * car_stat_resource.steering_angle * 0.6
	
	if steer_rotation != 0:
		var angle = clamp(fl_wheel.rotation.y + steer_rotation, -car_stat_resource.steering_angle, car_stat_resource.steering_angle)
		
		var new_rotation = angle * delta
		fl_wheel.rotation.y = move_toward(fl_wheel.rotation.y, new_rotation,  delta * car_stat_resource.steer_speed)
		fr_wheel.rotation.y = move_toward(fl_wheel.rotation.y, new_rotation,  delta * car_stat_resource.steer_speed)

	else:
		fl_wheel.rotation.y = move_toward(fl_wheel.rotation.y, 0.0, delta * car_stat_resource.steer_speed)
		fr_wheel.rotation.y = move_toward(fl_wheel.rotation.y, 0.0,  delta * car_stat_resource.steer_speed)

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
		rotation_direction = -1 if accel_input > 0 else 1
		fl_wheel_visual.rotate_x(rotation_direction * engine.power_output * 100 * delta)
		fr_wheel_visual.rotate_x(rotation_direction * engine.power_output * 100 * delta)
		br_wheel_visual.rotate_x(rotation_direction * engine.power_output * 100 * delta)
		bl_wheel_visual.rotate_x(rotation_direction * engine.power_output * 100 * delta)
	elif int(linear_velocity.z) != 0:
		# If moving, spin wheels in direction of forward velocity
		rotation_direction = -1  if linear_velocity.dot(basis.z) > 0 else 1
		# Wheel rotation speeds
		fl_wheel_visual.rotate_x(rotation_direction * linear_velocity.z * 100 * delta)
		fr_wheel_visual.rotate_x(rotation_direction * linear_velocity.z * 100 * delta)
		br_wheel_visual.rotate_x(rotation_direction * linear_velocity.z * 100 * delta)
		bl_wheel_visual.rotate_x(rotation_direction * linear_velocity.z * 100 * delta)

var speed_visual_threshold: float = 0.5

# Emit speed effects when going x% of max speed
func speed_visuals() -> void:
	if !normalized_speed >= speed_visual_threshold or linear_velocity.dot(-basis.z) <= 0.3:
		speed_particles.emitting = false
		# Fade light trail out slowly
		#left_light_trail.material_override.emission_energy_multiplier = lerpf(left_light_trail.material_override.emission_energy_multiplier, 16, normalized_speed/20)
		#right_light_trail.material_override.emission_energy_multiplier = lerpf(right_light_trail.material_override.emission_energy_multiplier, 16, normalized_speed/20)

		left_light_trail.material_override.albedo_color.a = lerpf(left_light_trail.material_override.albedo_color.a, 0, normalized_speed/20)
		right_light_trail.material_override.albedo_color.a = lerpf(left_light_trail.material_override.albedo_color.a, 0, normalized_speed/20)
		# Hide speed lines
		speed_lines_shader.visible = false
	else:
		speed_particles.amount = max_speed_particles * normalized_speed
		speed_particles.emitting = true
		left_light_trail.emit = true
		left_light_trail.material_override.emission_energy_multiplier = 16
		
		#left_light_trail.material_override.emission_energy_multiplier = 16 + 20 * (speed_visual_threshold - normalized_speed/1-speed_visual_threshold)
		right_light_trail.material_override.emission_energy_multiplier = 16 + 20 * (speed_visual_threshold - normalized_speed/1-speed_visual_threshold)
		right_light_trail.emit = true
		# Fade light trail in slowly :D
		left_light_trail.material_override.albedo_color = Color(car_stat_resource.light_trail_color, lerpf(left_light_trail.material_override.albedo_color.a, 0.01 , normalized_speed/200))
		right_light_trail.material_override.albedo_color = Color(car_stat_resource.light_trail_color, lerpf(right_light_trail.material_override.albedo_color.a, 0.010,  normalized_speed/200))
		# Show speed lines >>>>!
		speed_lines_shader.visible = true

# Turn on break lights when under breaking :D
func brake_light_visuals() -> void:
	pass

# Return current engine power
func get_engine_power() -> float:
	return engine.power_output

# Emit exhaust effects when changing gear
func _handle_exaust_emmision() -> void:
	exhaust.pop()

# Returns tire grip (between 0,1)
func get_tire_grip(traction: bool = false) -> float:
	if traction:
		return car_stat_resource.front_grip_curve.sample(normalized_speed)
	else:
		return car_stat_resource.rear_grip_curve.sample(normalized_speed)

# Switch current state to State.DRIVE so initial boost fades
func _on_neutral_drive_timeout() -> void:
	current_state = State.DRIVE

# Respawn player between last checkpoint and next checkpoint
func respawn() -> void:
	pass

# Enable player/bot collision
func _handle_respawn() ->void:
	pass

# Update checkpoint count
func add_checkpoint(new_current_checkpoint: int, new_target_checkpoint: int, add_lap: bool = false) -> void:
	current_checkpoint = new_current_checkpoint
	target_checkpoint = new_target_checkpoint
	if add_lap:
		current_lap += 1
		if current_lap == max_lap_count +1:
			race_over.emit(self)

# Start Race
func start_race() -> void:
	axis_lock_angular_y = false
	
	current_race_state = RaceState.RACE
	engine.start_race()

# Handle  end of race transition
func finish_race() -> void:
	pass


# TODO
# add respawn confirmation hit box so cant return collision inside object
# Add wrong way detection
