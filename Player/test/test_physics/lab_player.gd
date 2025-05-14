class_name LabPlayer extends CustomCar

# Camera Points
@onready var camera_points = $CameraShowCase
# Speed lines (overlay)
@onready var speed_lines_shader: ColorRect = $Control/ColorRect

signal lap_completed(player)

# Player instance variables
# Input map
@export var inputs = {}
# Player index
@export var player_index: int 
@export var player_name: String = ''

# Player camera (set to current)
@export var camera: PlayerCamera

var last_lap_time: float = 0.0

func _input(event: InputEvent) -> void:
	match current_race_state:
		RaceState.RACE:
			if event.is_action_pressed('ui_cancel'):
				get_tree().call_group('track', '_handle_pause', player_index)
		_:
			pass
	# TODO REMOVE
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()

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
			apply_force((-global_basis.y * 2500), $COMMID.position)
			apply_force((-global_basis.y * abs((state.linear_velocity * state.linear_velocity).dot(-global_basis.z))) * 5, $COMBACK.position)
			apply_force((-global_basis.y * abs((state.linear_velocity * state.linear_velocity).dot(-global_basis.z))) * 5, $COMFRONT.position)

func _physics_process(delta: float) -> void:
	match current_race_state:
		# State for pre race camera showroom
		RaceState.START:
			# Get player inputs
			# Acceleration
			accel_input = (Input.get_action_strength('ui_up')) - Input.get_action_strength('ui_down')
			# Steering
			steer_input =  Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left') * 0.8
			
			# Apply visual-input response
			steering(delta)
			wheel_visuals(delta)
			# Apply traction
		# State for active race participation, Set by main level
		RaceState.RACE:
			# Get player inputs, shared across states
			# Get player inputs
			# Acceleration
			accel_input = (Input.get_action_strength('ui_up')) - Input.get_action_strength('ui_down')
			# Steering
			steer_input = Input.get_action_strength('ui_left') - Input.get_action_strength('ui_right') * 0.8

			# Boost start input
			if Input.is_action_pressed('boost') and accel_input != 0:
				apply_boost()

			# Boost stop input
			if Input.is_action_just_released('boost'):
				stop_boost.emit()

			# State Machine, car function state
			match current_state:
				State.NEUTRAL:
					pass
				State.DRIVE:
					# Apply traction
					#Enter drift state
					if Input.is_action_just_pressed('drift') and abs(steer_input) >= 0.2:
						apply_torque_impulse(global_basis.y * steer_input * 500 * (0.1 + abs(accel_input)))
						apply_force(global_basis.x * 8000 * -steer_input, $COMBACK.position)
						current_state = State.DRIFT
						draw_arrow($COMBACK.global_position, global_basis.x * - steer_input, 1000, 'drift-impulse', Color.GHOST_WHITE)

					# If boost bar is not full, restore boost
					# Restore amount is standard rate

					# Exit condition
					# If not moving (approx.) and there is no acceleration input\
					# transition to neutral state
					if speed <= 0.3 and accel_input == 0:
						current_state = State.NEUTRAL

				State.DRIFT:
					pass
					# Apply traction
					# If boost bar is not full, restore boost
					# Restore amount is increased when boosting

					# TO NOTE, State exit condition is controlled by wheels\
					# if wheel lateral force is too low, State.DRIFT -> State.DRIVE

				State.DISABLED:
					# Stop car
					linear_velocity = Vector3.ZERO

			# Update current speed variables
			speed = abs(linear_velocity.dot(transform.basis.z))
			normalized_speed = engine.get_normalized_power_output()

			# Control steering
			steering(delta)
			# Update wheel visuals
			wheel_visuals(delta)
			# Apply Speed effects, speed particles and light trails
			speed_visuals()
			# Control break lights visibilty
			brake_light_visuals()

		RaceState.FINISH:
			pass

# Turn on break lights when under breaking :D
func brake_light_visuals() -> void:
	break_light_holder.visible = Input.is_action_pressed('ui_down')

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

func respawn():
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

# Getter to update engine data ui //
# Current gear
func get_current_gear() -> int:
	return engine.current_gear

# Current speed
func get_current_speed() -> int:
	return roundi(abs(linear_velocity.dot(transform.basis.z)*3.8))

# Current engine rpm
func get_current_engine_rpm() -> int:
	return engine.current_rpm

# Current boost reserve
func get_current_boost_reserve() -> float:
	return engine.current_boost_reserve
# // Engine ui data

# Update checkpoint count
func add_checkpoint(new_current_checkpoint: int, new_target_checkpoint: int, add_lap: bool = false) -> void:
	current_checkpoint = new_current_checkpoint
	target_checkpoint = new_target_checkpoint
	if add_lap:
		current_lap += 1
		lap_completed.emit(self)
		if current_lap == max_lap_count +1:
			race_over.emit(self)

	$Label3D.text = 'Current CHeck %s \n target: %s \n %s' % [str(current_checkpoint), str(target_checkpoint), str(current_lap)]

# Enable player/bot collision
func _handle_respawn() ->void:
	# TODO
	# Add collisions
	set_collision_layer_value(2, true)
	# Set bot collision to true
	set_collision_mask_value(4, true)
	# Set player collision to true
	set_collision_mask_value(2, true)

# Disable car funcitions and notify game player has finished
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

func draw_arrow(start: Vector3, direction: Vector3, magnitude: float, group: String, color: Color = Color.ALICE_BLUE) -> void:

	for node in get_children():
		if node.is_in_group(group):
			node.queue_free()
			
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.top_level = true
	mesh_instance.add_to_group(group)
	var mesh = ImmediateMesh.new()

	# Update mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(start + (direction * abs(magnitude)))

	# End drawing.
	mesh.surface_end()
	mesh_instance.mesh = mesh
	
	var mesh_shader = StandardMaterial3D.new()
	mesh_shader.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_shader.albedo_color = color
	mesh_shader.vertex_color_use_as_albedo = true
	
	mesh_instance.set_material_override(mesh_shader)
	
	
	add_child(mesh_instance)
