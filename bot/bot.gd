class_name Bot extends RigidBody3D

signal race_over(bot: Bot)

@export var car_stat_resource: CarStats
# Car function variables
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

var fr_visual_start_position: Vector3
var fl_visual_start_position: Vector3
var br_visual_start_position: Vector3
var bl_visual_start_position: Vector3

# Direction assessment variables
@onready var ray_holder = $RayHolder
@export var path: Path3D

var num_rays = 12
var ray_length: float = 50.0
var sample_rate: int = 4
var next_path_point: Vector3
var points: PackedVector3Array
var points_index: int = 0

var chosen_direction: Vector3

var intrest_array: Array[float] = []
var danger_array: Array[float] = []
var ray_directions: Array[Vector3] = []

var max_dist: int = 0
var min_dist: int = 10

# Danger assessment variables
# Avoidance for other bots
@export var bot_avoidance: float = 0.1
# Avoidance for players
@export var player_avoidance: float = 0.0
# Avoidance for other walls
@export var obstacle_avoidance: float = 0.15

# Race variables
@export var max_lap_count: int
# Checkpoint refernce for all checkpoints returned by Track class
@export var checkpoint_array = []
@export var current_checkpoint : int = 0
@export var target_checkpoint: int = 1
var distance_to_checkpoint: float
@export var current_lap: int = 1

var start_position: Vector3
var normalized_speed: float = 0.0
var accel_input: float = 0.0
var speed: float
var max_speed_particles: int = 30
var max_turn_angle: int = 30
var traction_value: int = 10000

var max_boost_reserve: float = 10.0
var current_boost_reserve: float
var current_boost_multiplier: float = 1.0
var max_boost_multiplier: float = 2.0
var boost_regen_rate_drive: float = 0.1
var boost_regen_rate_drift: float = 0.2
var boost_consumption_rate: float = 0.5

# State machine
enum RaceState {START, RACE, FINISH}
enum State {NEUTRAL, DRIVE, DRIFT, DISABLED}

# Starting states 
var current_state = State.NEUTRAL
var current_race_state = RaceState.START

# Timers
@onready var respawn_timer: Timer = $RespawnTimer


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()

func _ready() -> void:
	# Load car stats form resource
	setup_car()
	# Set varirables for context based steering
	setup_context_based_steering()
	# Get and store track path points
	points = path.curve.get_baked_points()
	# Set poisition on start grid
	global_position = start_position
	
	# Timer properites
	respawn_timer.timeout.connect(_handle_respawn)

func _process(delta: float) -> void:
	distance_to_checkpoint = global_position.distance_to(checkpoint_array[target_checkpoint].global_position)

func _physics_process(delta: float) -> void:
	match current_race_state:
		RaceState.START:
			global_position.x = start_position.x
			global_position.z = start_position.z
			apply_traction(traction_value)
			var rand_input = randi_range(0, 20)
			if rand_input < 3:
				accel_input = randf_range(0.5, 1.0)
			else:
				accel_input = 0
		RaceState.RACE:
			apply_traction(traction_value)
			if global_position.distance_to(next_path_point) <= min_dist or points_index == 0 or global_position.distance_to(next_path_point) > max_dist:
				set_intrests()
				set_danger()
				choose_direction()
			
				match current_state:
					State.DRIVE:
						if current_boost_reserve < max_boost_reserve and current_boost_multiplier != max_boost_multiplier:
							current_boost_reserve = clampf(current_boost_reserve + boost_regen_rate_drive, current_boost_reserve, max_boost_reserve)
					_:
						if current_boost_reserve < max_boost_reserve:
							current_boost_reserve = clampf(current_boost_reserve + boost_regen_rate_drift, current_boost_reserve, max_boost_reserve)

			var desired_velocity: Vector3 = chosen_direction

			steering(delta)
			speed = linear_velocity.dot(-transform.basis.z)
			
			normalized_speed = clampf(speed/car_stat_resource.max_speed, 0.0, 1.0)
			accel_input = desired_velocity.dot(-transform.basis.z) if desired_velocity.dot(-transform.basis.z)!= 0 else -0.5
		RaceState.FINISH:
			pass
	# Update wheel visuals
	wheel_visuals(delta)
	# Apply Speed effects, speed particles and light trails
	speed_visuals()

# Load and apply car stats form car_stat_resource
func setup_car() -> void:
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

# Setup Bot variables for context based steering
func setup_context_based_steering() -> void:
	# Resize context arrays to the given number or decision rays
	intrest_array.resize(num_rays)
	danger_array.resize(num_rays)
	# Set up decision rays
	for i in num_rays:
		# Create decision ray
		var ray = RayCast3D.new()

		# Calculate y axis rotation angle for each ray
		var angle = i * 2 * PI / num_rays
		
		# Populate danger array with default values
		danger_array[i] = 1
		
		# Set decision ray distance and rotation
		ray.target_position = Vector3(0, 0, -ray_length)
		ray.rotate(Vector3.UP, angle)
		
		# Store ray direction in ray_directions array
		ray_directions.append(Vector3.FORWARD.rotated(Vector3.UP, angle))
		
		# Add ray as child of Bot/ray_holder
		ray_holder.add_child(ray)

# Set intrest direction based on world direction and target direction
func set_intrests() -> void:
	# Use new sample index to find next path point target
	points_index += sample_rate
	
	if global_position.distance_to(next_path_point) <= 5.0:
		points_index += sample_rate * 20
		if points_index >= points.size():
			points_index = sample_rate * 20
		next_path_point = points[points_index] * path.scale
	
	if points_index >= points.size():
		var next_point: float = points.size() - points_index
		points_index = next_point

	# Set new path point and covert to global coordinates
	next_path_point = points[points_index] * path.scale

	# Get direction to closest point
	var target_direction = global_position.direction_to(next_path_point)
	max_dist = global_position.distance_to(next_path_point) + 10

	for i in num_rays:
		var d = ray_directions[i].dot(target_direction * global_position.distance_to(next_path_point))
		intrest_array[i] = max(0, d)

# Cast a ray in each direction. If there’s a hit, we add a 1 in that spot.
func set_danger() -> void:
	var space_state = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D
	var result: Dictionary
	
	# For each direction ray, handle ray collision
	for i in num_rays:
		# Query danger ray >:D
		query = PhysicsRayQueryParameters3D.create(ray_holder.global_position, ray_holder.global_position + (ray_directions[i] * ray_length), pow(2, 2-1) + pow(2, 6-1) + pow(2, 4-1), [self])
		# Get query result
		result = space_state.intersect_ray(query)
		# Handle result, set danger[0,1] (total avoid, ignore)
		if !result.is_empty():
			if result.collider.is_in_group('obstacle'):
				danger_array[i] = obstacle_avoidance
			elif result.collider.is_in_group('player'):
				danger_array[i] = player_avoidance
			elif result.collider.is_in_group('bot'):
				danger_array[i] = bot_avoidance
		else:
			danger_array[i] = 1

# Finalise current direction vector 
func choose_direction() -> void:
	# Reset chosen direction
	chosen_direction = Vector3.ZERO

	# Adjust intrest array if danger value exits at index in danger array
	for i in num_rays:
		intrest_array[i] *= danger_array[i]
		chosen_direction += ray_directions[i] * intrest_array[i]

	chosen_direction = chosen_direction.normalized()

# Apply traction force to car center
func apply_traction(value: int) -> void:
	apply_central_force(-transform.basis.y  * value)

# Handle steering toward chosen direction
func steering(delta: float) -> void:
	fl_wheel.look_at(global_position + chosen_direction * global_position.distance_to(next_path_point))
	fr_wheel.look_at(global_position + chosen_direction * global_position.distance_to(next_path_point))

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
		fr_wheel_visual.rotate_x(rotation_direction * linear_velocity.z * 100 * delta)
		fl_wheel_visual.rotate_x(rotation_direction * linear_velocity.z * 100 * delta)
		br_wheel_visual.rotate_x(rotation_direction * get_torque(normalized_speed) * 100 * delta)
		bl_wheel_visual.rotate_x(rotation_direction * get_torque(normalized_speed) * 100 * delta)
	else:
		# If moving, spin wheels in direction of forward velocity
		rotation_direction = 1  if linear_velocity.dot(basis.z) > 0 else -1
		fr_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * 100 * delta)
		fl_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * 100 * delta)
		br_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * 100 * delta)
		bl_wheel_visual.rotate_x(rotation_direction * linear_velocity.length() * 100 * delta)

# Emit speed effects when going x% of max speed
func speed_visuals() -> void:
	if !normalized_speed >= 0.75:
		speed_particles.emitting = false
		# Fade light trail out slowly
		left_light_trail.material_override.albedo_color.a = lerpf(left_light_trail.material_override.albedo_color.a, 0, normalized_speed/20)
		right_light_trail.material_override.albedo_color.a = lerpf(left_light_trail.material_override.albedo_color.a, 0, normalized_speed/20)
	else:
		speed_particles.amount = max_speed_particles * normalized_speed
		speed_particles.emitting = true
		left_light_trail.emit = true
		right_light_trail.emit = true
		# Fade light trail in slowly :D
		left_light_trail.material_override.albedo_color = Color(car_stat_resource.light_trail_color, lerpf(left_light_trail.material_override.albedo_color.a, 0.01 , normalized_speed/200))
		right_light_trail.material_override.albedo_color = Color(car_stat_resource.light_trail_color, lerpf(right_light_trail.material_override.albedo_color.a, 0.010,  normalized_speed/200))

# Return torque value from torque graph
func get_torque(curent_normalized_speed: float) -> float:
	return car_stat_resource.torque_curve.sample(curent_normalized_speed)

# Returns tire grip (between 0,1)
func get_tire_grip(traction: bool = false) -> float:
	if traction:
		return car_stat_resource.front_grip_curve.sample(normalized_speed)
	else:
		return car_stat_resource.rear_grip_curve.sample(normalized_speed)

# Return bot to checkpoint when out of bounds
func respawn() -> void:
	# Hide car during respawn transition
	current_state = State.DISABLED
	freeze = true
	linear_velocity = Vector3.ZERO
	hide()
	# Remove collisions
	set_collision_layer_value(4, false)
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
	# Start collision timer
	respawn_timer.start()
	# Hand back player control
	await get_tree().create_timer(0.25).timeout
	freeze = false
	current_state = State.DRIVE

# Enable player/bot collision
func _handle_respawn() ->void:
	# Bot collider
	set_collision_layer_value(4, true)
	# Other Bot collision layer
	set_collision_mask_value(4, true)
	# Player collision layer
	set_collision_mask_value(2, true)

# Tally checkpoint progress
func add_checkpoint(new_current_checkpoint: int, new_target_checkpoint: int, add_lap: bool = false) -> void:
	current_checkpoint = new_current_checkpoint
	target_checkpoint = new_target_checkpoint
	if add_lap:
		current_lap += 1
		if current_lap == max_lap_count +1:
			race_over.emit(self)

# Start Race
func start_race() -> void:
	lock_rotation = false
	current_race_state = RaceState.RACE
	current_state = State.NEUTRAL

# Handle  end of race transition
func finish_race() -> void:
	current_state = State.DISABLED
	set_collision_layer_value(4, false)
	set_collision_layer_value(5, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	set_collision_mask_value(3, false)
	set_collision_mask_value(4, false)
	hide()
	
	current_race_state = RaceState.FINISH
	
