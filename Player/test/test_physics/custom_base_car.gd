class_name PlayerCar extends RigidBody3D

# Race ready signal, emited by camera when showcase is over
signal race_ready()
# Race over signal, 0 laps remaining
signal race_over(player: PlayerCar, finish_position: int)

# Player instance variables
# Grid start position (global coordinates)
@export var start_position: Vector3
# Input map
@export var inputs = {}
# Player index
@export var player_index: int 

# Player camera (set to current)
@export var camera: PlayerCamera

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
@onready var fl_wheel = $FrontRightWheel
@onready var fr_wheel = $FrontLeftWheel
@onready var bl_wheel = $BackLeftWheel
@onready var br_wheel = $BackRightWheel

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
var current_state = State.NEUTRAL
var current_race_state = RaceState.START

# Timers
# Timer to remove neutral torque boost when moving from State.NEUTRAL to State,DRIVE
@onready var neutral_transition_timer: Timer = $NeutralTransitionTimer
# Respawn timer to re-enable PlayerCar and Bot collisions
@onready var respawn_timer: Timer = $RespawnTimer

# BOOST VARIBLES !!!
# Maximum avalible boost
var max_boost_reserve: float = 10.0
# Boost currently availble
var current_boost_reserve: float
# BOOST POWER (parsed to wheels to multiply acceleration force)
var current_boost_multiplier: float = 1.0
# MAX BOOST POWER (parsed to wheels to multiply acceleration force)
var max_boost_multiplier: float = 2.0
# Boost regen rates ><
var boost_regen_rate_drive: float = 0.1
var boost_regen_rate_drift: float = 0.2
# Boost consumption rates :D
var boost_consumption_rate: float = 0.5


func _ready() -> void:
	lock_rotation = true
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
	
	# Timer properites
	neutral_transition_timer.wait_time = 0.5
	neutral_transition_timer.timeout.connect(_on_neutral_drive_timeout)
	neutral_transition_timer.one_shot = true
	
	current_boost_reserve = max_boost_reserve
	
	points = path.curve.get_baked_points()
	
	respawn_timer.timeout.connect(_handle_respawn)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	pass


func _input(event: InputEvent) -> void:
	match current_race_state:
		RaceState.RACE:
			if event.is_action_pressed(inputs['buttons']['menu']['control_string']):
				get_tree().call_group('track', '_handle_pause', player_index)
		_:
			pass
	# TODO REMOVE
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()


func _process(delta: float) -> void:
	distance_to_checkpoint = global_position.distance_to(checkpoint_array[target_checkpoint].global_position)

func _physics_process(delta: float) -> void:
	match current_race_state:
		# State for pre race camera showroom
		RaceState.START:
			# Apply traction
			apply_traction()

			# Keep player in position, allow for y axis_movement
			global_position.x = start_position.x
			global_position.z = start_position.z

			# Get player inputs
			# Acceleration
			
			accel_input = (Input.get_action_strength(inputs['motions']['up']['control_string']) - Input.get_action_strength(inputs['motions']['down']['control_string']))
			# Steering
			steer_input = Input.get_action_strength(inputs['motions']['left']['control_string']) - Input.get_action_strength(inputs['motions']['right']['control_string']) * 0.8
			
			# Apply visual-input response
			steering(delta)
			wheel_visuals(delta)
		# State for active race participation, Set by main level
		RaceState.RACE:
			# Get player inputs, shared across states
			# Get player inputs
			# Acceleration
			accel_input = (Input.get_action_strength(inputs['motions']['up']['control_string']) - Input.get_action_strength(inputs['motions']['down']['control_string']))
			# Steering
			steer_input = Input.get_action_strength(inputs['motions']['left']['control_string']) - Input.get_action_strength(inputs['motions']['right']['control_string']) * 0.8

			#if accel_input != 0:
				#linear_damp = 1
			#else:
				#linear_damp = lerpf(linear_damp, 50, delta )
			#

			# Boost start input
			if Input.is_action_pressed(inputs['buttons']["boost"]['control_string']) and accel_input != 0:
				apply_boost()

			# Boost stop input
			if Input.is_action_just_released(inputs['buttons']["boost"]['control_string']):
				current_boost_multiplier = 1.0

			# State Machine, car function state
			match current_state:
				State.NEUTRAL:
					# Apply traction
					apply_traction()

					# Exit condition
					# On receving acceleration input, ensure torque boost timer starts/has started\
					# neutral_transition_timer.timeout signal response will exit to DRIVE state
					if accel_input != 0 and neutral_transition_timer.is_stopped():
						neutral_transition_timer.start()

				State.DRIVE:
					# Apply traction
					apply_traction()

					#Enter drift state
					if Input.is_action_just_pressed(inputs['buttons']["drift"]['control_string']):
						current_state = State.DRIFT

					# If boost bar is not full, restore boost
					# Restore amount is standard rate
					if current_boost_reserve < max_boost_reserve:
						current_boost_reserve = regen_boost(boost_regen_rate_drive)
	
					# Exit condition
					# If not moving (approx.) and there is no acceleration input\
					# transition to neutral state
					if speed <= 0.3 and accel_input == 0:
						current_state = State.NEUTRAL

				State.DRIFT:
					# Apply traction
					apply_traction()
					
					# If boost bar is not full, restore boost
					# Restore amount is increased when boosting
					if current_boost_reserve < max_boost_reserve:
						current_boost_reserve = regen_boost(boost_regen_rate_drift)
						
					# TO NOTE, State exit condition is controlled by wheels\
					# if wheel lateral force is too low, State.DRIFT -> State.DRIVE

				State.DISABLED:
					# Stop car
					linear_velocity = Vector3.ZERO

			# Update current speed variables
			speed = abs(linear_velocity.dot(transform.basis.z))
			normalized_speed = clampf(speed/car_stat_resource.max_speed, 0.0, 1.0)

			# Control steering
			steering(delta)
			# Update wheel visuals
			wheel_visuals(delta)
			# Apply Speed effects, speed particles and light trails
			speed_visuals()
		
		RaceState.FINISH:
			pass
		
# Apply traction force to car center of mass
func apply_traction() -> void:
	var y_dir = path.curve.sample_baked_up_vector(path.curve.get_closest_offset(path.to_local(global_position)), true)
	apply_force(-y_dir  * mass * 20 *normalized_speed, $COMMID.position)

# Consume boost
func apply_boost() -> void:
	current_boost_reserve -= boost_consumption_rate
	if current_boost_reserve > 0:
		current_boost_multiplier = max_boost_multiplier
	else:
		current_boost_reserve = 0
		current_boost_multiplier = 1.0

# Regenerate boost by given rate per delta
func regen_boost(regen_rage: float) -> float:
	return clampf(current_boost_reserve + regen_rage, current_boost_reserve, max_boost_reserve)

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
		fl_wheel_visual.rotate_x(rotation_direction * linear_velocity.z * delta)
		fr_wheel_visual.rotate_x(rotation_direction * linear_velocity.z * delta)
		br_wheel_visual.rotate_x(rotation_direction * get_torque(normalized_speed) * 100 * delta)
		bl_wheel_visual.rotate_x(rotation_direction * get_torque(normalized_speed) * 100 * delta)
	elif int(linear_velocity.z) != 0:
		# If moving, spin wheels in direction of forward velocity
		rotation_direction = -1  if linear_velocity.dot(basis.z) > 0 else 1
		# Wheel rotation speeds
		fl_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * 100 * delta)
		fr_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * 100 * delta)
		br_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * 100 * delta)
		bl_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * 100 * delta)

# Emit speed effects when going x% of max speed
func speed_visuals() -> void:
	if !normalized_speed >= 0.75:
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

# Switch current state to State.DRIVE so initial boost fades
func _on_neutral_drive_timeout() -> void:
	current_state = State.DRIVE

# Respawn player between last checkpoint and next checkpoint
func respawn() -> void:
	# Remove player control by setting state to disabled
	current_state = State.DISABLED
	freeze = true
	linear_velocity = Vector3.ZERO
	# Hide car during respawn transition

	hide()
	# Remove collisions
	set_collision_layer_value(2, false)
	# Other player collion layer
	set_collision_mask_value(2, false)
	# Bot collion layer
	set_collision_mask_value(4, false)
	
	# Find what checkpoint player most recently passed sucessfully
	# Get all checkpoints in tree
	var checkpoints  = get_tree().get_nodes_in_group('checkpoint')
	
	# Loop to find which checkpoint index == players current checkpoint
	for checkpoint: CheckPoint in checkpoints:
		# Checkpoint index == players current checkpoint
		if checkpoint.checkpoint_index == current_checkpoint:
		
			var closest_point: Vector3
			if current_checkpoint == 0:
				# Find the closest pooint to last known checkpoint
				closest_point  = path.curve.get_closest_point(path.to_local(checkpoints[-1].global_position))
			else:
				# Find the closest pooint to last known checkpoint
				closest_point = path.curve.get_closest_point(path.to_local(checkpoint.global_position))

			# Find index of closest_point in baked points array
			var closest_point_index: int = points.find(closest_point)

			# Find the closest point from next checkpoint
			# Get next checkpoint
			var next_checkpoint_index: int
			if current_checkpoint == 0:
				next_checkpoint_index = 0
			else:
				next_checkpoint_index = checkpoint.checkpoint_target

			# Set index to 0 if at final checkpoint
			if next_checkpoint_index >= checkpoints.size():
				next_checkpoint_index = 0

			# Find closest point from next checkpoint
			var future_point: Vector3 = path.curve.get_closest_point(path.to_local(checkpoints[next_checkpoint_index].global_position))

			# Find index of future_point in baked points array
			var future_point_index: int = points.find(future_point)

			# Handle edge cases...
			# Not found...
			if closest_point_index == -1:
				closest_point_index = future_point_index

			# Approaching final checkpoint...
			if future_point_index == 0:
				future_point_index = points.size() -1

			# Get mid point between checkpoints
			# Mid point index
			var mid_point_index = floor((closest_point_index + future_point_index) / 2)
			# Mid point global position
			var mid_point_position = points[mid_point_index] * path.scale
			
			# Find direction to face
			# Get future point from midpoint
			var future_path_point_index = mid_point_index + 20

			if future_path_point_index >= points.size():
				future_path_point_index = points.size() - future_path_point_index + 1
			
			# Calculate distance future point to face
			var look_direction = points[mid_point_index + 10].direction_to(points[future_path_point_index]) * path.scale * 400
			
			# Rotate to look at future point
			look_at(look_direction)
			
			# Set car back on track, just above wheel contact
			global_position = mid_point_position + (checkpoint.global_transform.basis.y * car_stat_resource.wheel_radius * 2)
			break
	
	# Show car
	show()
	# Regain camera control
	camera.can_follow = true
	# Start collision timer
	respawn_timer.start()
	# Hand back player control
	await get_tree().create_timer(0.25).timeout
	freeze = false
	current_state = State.DRIVE

# Enable player/bot collision
func _handle_respawn() ->void:
	# TODO
	# Add collisions
	set_collision_layer_value(2, true)
	# Set bot collision to true
	set_collision_mask_value(4, true)
	# Set player collision to true
	set_collision_mask_value(2, true)

# Update checkpoint count
func add_checkpoint(new_current_checkpoint: int, new_target_checkpoint: int, add_lap: bool = false) -> void:
	current_checkpoint = new_current_checkpoint
	target_checkpoint = new_target_checkpoint
	if add_lap:
		current_lap += 1
		if current_lap == max_lap_count +1:
			race_over.emit(self)

	$Label3D.text = 'Current CHeck %s \n target: %s \n %s' % [str(current_checkpoint), str(target_checkpoint), str(current_lap)]

# Start Race
func start_race() -> void:
	lock_rotation = false
	current_race_state = RaceState.RACE

# Handle  end of race transition
func finish_race() -> void:
	camera.can_follow = false
	current_state = State.DISABLED
	set_collision_layer_value(2, false)
	set_collision_layer_value(5, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	set_collision_mask_value(3, false)
	set_collision_mask_value(4, false)
	hide()
	
	get_tree().call_group('track', '_handle_race_over', player_index)
	current_race_state = RaceState.FINISH
	
	# TODO player finish anim

# TODO
# add respawn confirmation hit box so cant return collision inside object
# Add wrong way detection
