class_name Bot extends CustomCar


@onready var ray_holder = $RayHolder
# Turn on break lights when under breaking :D
func brake_light_visuals() -> void:
	break_light_holder.visible = Input.is_action_pressed('ui_down')

# Direction assessment variables
# Number of detection rays
var num_rays = 12
var ray_length: float = 50.0
var sample_rate: int = 100
var next_path_point: Vector3
var points_index: int = 0

var chosen_direction: Vector3

var intrest_array: Array[float] = []
var danger_array: Array[float] = []
var ray_directions: Array[Vector3] = []

var max_dist: int = 0
var min_dist: int = 10

# Danger assessment variables
# Avoidance for other bots
@export var bot_avoidance: float = 0.3
# Avoidance for players
@export var player_avoidance: float = 0.0
# Avoidance for other walls
@export var obstacle_avoidance: float = 0.15

# Race variables
var max_boost_reserve: float = 10.0
var current_boost_reserve: float
var current_boost_multiplier: float = 1.0
var max_boost_multiplier: float = 2.0
var boost_regen_rate_drive: float = 0.1
var boost_regen_rate_drift: float = 0.2
var boost_consumption_rate: float = 0.5

var up_vectors: PackedFloat32Array
var previous_accel_input: float

func _ready() -> void:
	# Set up car
	super._ready()
	# Set varirables for context based steering
	setup_context_based_steering()
	# Get and store track path points
	points = path.curve.get_baked_points()
	up_vectors = path.curve.get_baked_tilts()
	

func _process(delta: float) -> void:
	distance_to_checkpoint = global_position.distance_to(checkpoint_array[target_checkpoint].global_position)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	match current_race_state:
		RaceState.START:
			# Keep player in position, allow for y axis_movement
			global_position.x = start_position.x
			global_position.z = start_position.z
			apply_force((-global_basis.y * 9.8), $COMMID.position)
		RaceState.RACE:
			apply_force((-global_basis.y * 4500), $COMMID.position)
			apply_force((-global_basis.y * abs((state.linear_velocity * state.linear_velocity).dot(-global_basis.z))) * 5, $COMBACK.position)
			apply_force((-global_basis.y * abs((state.linear_velocity * state.linear_velocity).dot(-global_basis.z))) * 5, $COMFRONT.position)

func _physics_process(delta: float) -> void:
	match current_race_state:
		RaceState.START:
			global_position.x = start_position.x
			global_position.z = start_position.z
			var rand_input = randi_range(0, 10)
			if rand_input < 3:
				accel_input = 0
			else:
				accel_input = 1
		RaceState.RACE:
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

			normalized_speed = engine.get_normalized_power_output()
			var accel_dir = chosen_direction.dot(-global_basis.z)

			$ChosenDir.global_position = global_position + chosen_direction * global_position.distance_to(next_path_point)

			var check = false
			var speed = linear_velocity.dot(-global_basis.z)

			if accel_dir > -0.3:
				var combined_decel: float = 0.0
				for ray: RayCast3D in $DecelRayHolder.get_children():
					ray.target_position.z = -25 * abs(normalized_speed)
					ray.force_raycast_update()
					if ray.is_colliding() and speed > 10:
						if ray.get_collider().is_in_group('obstacle') or ray.get_collider().is_in_group('player'):
							check = true
							var distance: float = global_position.distance_to(ray.get_collision_point())
							var obj: Node = ray.get_collider()
							combined_decel += distance/abs(ray.target_position.z)

				var average_decel = combined_decel/$DecelRayHolder.get_child_count()

				accel_input = maxf(-average_decel, -1.0) if check else 1.0
				
			else:
				accel_input = -1
			
			
			previous_accel_input = accel_input
			steering(delta)
		
		RaceState.FINISH:
			pass
	# Update wheel visuals
	wheel_visuals(delta)
	# Apply Speed effects, speed particles and light trails
	speed_visuals()

	# Show break light 
	break_light_holder.visible = accel_input < 0.3

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
	points_index += sample_rate * 1.25
	if points_index >= points.size():
		var next_point: float = points.size() - points_index
		points_index = next_point

	var point = points[points_index] * path.scale
	var offset = path.curve.get_closest_offset(point)
	var next_path_point_transform = path.curve.sample_baked_with_rotation(offset, false, true)
	next_path_point = next_path_point_transform.origin
	
	var closest_offset_to_car = path.curve.get_closest_offset(path.to_local(global_position))
	var closest_car_point = path.curve.sample_baked(closest_offset_to_car)

	if closest_car_point.distance_to(next_path_point) <= 5.0:
		points_index += sample_rate
		if points_index >= points.size():
			var next_point: float = points.size() - points_index
			points_index = next_point

		point = points[points_index]* path.scale
		offset = path.curve.get_closest_offset(point)
		next_path_point_transform = path.curve.sample_baked_with_rotation(offset, false, true)
		next_path_point = next_path_point_transform.origin

	## Set new path point and covert to global coordinates

	# Get direction to closest point
	var target_direction = global_position.direction_to(next_path_point + next_path_point_transform.basis.y * car_stat_resource.wheel_radius * 2 )
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

# Handle steering toward chosen direction, rotate 
# Rotate wheels to face target point
func steering(delta: float) -> void:
	$fr_marker.look_at((global_position + fr_wheel.position.x *  global_basis.x ) + chosen_direction * global_position.distance_to(next_path_point))
	$fl_marker.look_at((global_position + fl_wheel.position.x * global_basis.x) + chosen_direction * global_position.distance_to(next_path_point))
		
	## Debug marker placemetn
	$frt.global_position = (global_position + fr_wheel.position.x * global_basis.x ) + chosen_direction * global_position.distance_to(next_path_point)
	$flt.global_position = (global_position + fl_wheel.position.x * global_basis.x ) + chosen_direction * global_position.distance_to(next_path_point)
	
	fl_wheel.look_at((global_position + fl_wheel.position.x *  global_basis.x ) + chosen_direction * global_position.distance_to(next_path_point))
	fr_wheel.rotation_degrees.y = clampf(fr_wheel.rotation_degrees.y, -80, 80)
	fl_wheel.rotation.x = 0
	fl_wheel.rotation.z = 0

	#var fr_target_degrees = move_toward(fr_wheel.rotation_degrees.y, $fr_marker.rotation_degrees.y, delta)
	#fr_wheel.rotation_degrees = Vector3(0, fr_target_degrees, 0)
	#
	#var fl_target_degrees = move_toward(fl_wheel.rotation_degrees.y, $fl_marker.rotation_degrees.y, delta)
	#fl_wheel.rotation_degrees = Vector3(0, fl_target_degrees, 0)
	#
	fr_wheel.look_at((global_position + fr_wheel.position.x *  global_basis.x ) + chosen_direction * global_position.distance_to(next_path_point))
	fr_wheel.rotation_degrees.y = clampf(fr_wheel.rotation_degrees.y, -80, 80)
	fr_wheel.rotation.x = 0
	fr_wheel.rotation.z = 0
	
	#print(rad_to_deg(fl_wheel.rotation.y), 'l')
	#print(rad_to_deg(fr_wheel.rotation.y), 'r')

# Emit speed effects when going x% of max speed
func speed_visuals() -> void:
	if !normalized_speed >= speed_visual_threshold or linear_velocity.dot(-basis.z) <= 0.3:
		speed_particles.emitting = false
		# Fade light trail out slowly
		#left_light_trail.material_override.emission_energy_multiplier = lerpf(left_light_trail.material_override.emission_energy_multiplier, 16, normalized_speed/20)
		#right_light_trail.material_override.emission_energy_multiplier = lerpf(right_light_trail.material_override.emission_energy_multiplier, 16, normalized_speed/20)

		left_light_trail.material_override.albedo_color.a = lerpf(left_light_trail.material_override.albedo_color.a, 0, normalized_speed/20)
		right_light_trail.material_override.albedo_color.a = lerpf(left_light_trail.material_override.albedo_color.a, 0, normalized_speed/20)
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
