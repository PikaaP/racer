class_name Bot extends RigidBody3D

signal win(bot: Bot)

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

var num_rays = 16
var ray_length: float = 10.0
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
@export var bot_avoidance := 0.3
@export var player_avoidance: float = 0.2

# Race variables
@export var max_lap_count := 2
@export var current_checkpoint : int
@export var target_checkpoint: int
@export var current_lap: int

var start_position: Vector3
var respawning: bool = false
var is_difting: bool = false
var can_move: bool = true
var normalized_speed: float = 0.0
var accel_input: float = 0.0
var speed: float
var max_speed_particles: int = 30
var max_turn_angle = 30

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
	
	$BotCam.current = true

func _process(delta: float) -> void:
	# Apply traction
	apply_central_force(-transform.basis.y * 500)
	if not respawning:
		if global_position.distance_to(next_path_point) <= min_dist or points_index == 0 or global_position.distance_to(next_path_point) > max_dist:
			set_intrests()
			set_danger()
			choose_direction()
		
		var desired_velocity: Vector3 = chosen_direction
#
		steering(delta)
		#speed = abs(linear_velocity.dot(transform.basis.z))
		speed = linear_velocity.dot(-transform.basis.z)
		
		normalized_speed = clampf(speed/car_stat_resource.max_speed, 0.0, 1.0)
		accel_input = desired_velocity.dot(-transform.basis.z) if desired_velocity.dot(-transform.basis.z)!= 0 else -0.5

	# Update wheel visuals
	wheel_visuals(delta)
	# Apply Speed effects, speed particles and light trails
	speed_visuals()

# Load and apply car stats form car_stat_resource
func setup_car() -> void:
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
		query = PhysicsRayQueryParameters3D.create(ray_holder.global_position, ray_holder.global_position + ray_directions[i] * ray_length, pow(2, 1-1) + pow(2, 4-1), [self])
		# Get query result
		result = space_state.intersect_ray(query)
		# Handle result, set danger[0,1] (total avoid, ignore)
		if !result.is_empty():
			if result.collider.is_in_group('obstacle'):
				danger_array[i] = 0.1
			elif result.collider.is_in_group('player'):
				danger_array[i] = player_avoidance
			elif result.collider.is_in_group('bot'):
				danger_array[i] = 0.1
		else:
			danger_array[i] = 1

# Finalise current direction vector 
func choose_direction() -> void:
	# Reset chosen direction
	chosen_direction = Vector3.ZERO

	# Adjust intrest array if danger value exits at index in danger array
	for i in num_rays:
		if i == num_rays -1:
			if danger_array[i-1] != 1 or danger_array[0] != 1:
				if danger_array[i] != 1:
					danger_array[i] = (danger_array[i-1] + danger_array[0])/2
		else:
			if danger_array[i-1] != 1 or danger_array[i+1] != 1:
				if danger_array[i] != 1:
					danger_array[i] = (danger_array[i-1] + danger_array[i+1])/2

		intrest_array[i] *= danger_array[i]
		chosen_direction += ray_directions[i] * intrest_array[i]

	chosen_direction = chosen_direction.normalized()

# Handle steering toward chosen direction
func steering(delta: float) -> void:
	fl_wheel.look_at(global_position + chosen_direction * global_position.distance_to(next_path_point))
	fr_wheel.look_at(global_position + chosen_direction * global_position.distance_to(next_path_point))


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

# Emit speed effects when going x% of max speed
func speed_visuals() -> void:
	if !normalized_speed >= 0.50:
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
	apply_central_force(Vector3.ZERO)
	respawning = true
	hide()
	gravity_scale = 0
	mass = 0
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
	var checkpoints  = get_tree().get_nodes_in_group('checkpoint')
	var tween = get_tree().create_tween()
	for checkpoint: CheckPoint in checkpoints:
		if checkpoint.checkpoint_index == current_checkpoint:
			transform.basis =  checkpoint.transform.basis
			var start_pos = global_position
			tween.tween_property(self, "global_position", checkpoint.global_position + Vector3.UP * 2, 1.2)
			rotate_y(deg_to_rad(180))
			break
	await  tween.finished
	_handle_respawn()

# Handle repositioning on track
func _handle_respawn() ->void:
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	mass = car_stat_resource.mass
	gravity_scale = 1
	respawning = false
	show()

# Tally checkpoint progress
func add_checkpoint(new_current_checkpoint: int, new_target_checkpoint: int, add_lap: bool = false) -> void:
	current_checkpoint = new_current_checkpoint
	target_checkpoint = new_target_checkpoint
	if add_lap:
		current_lap += 1
		if current_lap == max_lap_count +1:
			win.emit(self)
