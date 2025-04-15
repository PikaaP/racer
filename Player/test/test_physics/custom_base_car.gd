class_name PlayerCar extends CustomCar

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
	
	points = path.curve.get_baked_points()
	
	respawn_timer.timeout.connect(_handle_respawn)
	
	# Setup Engine
	engine.emit_exaust.connect(_handle_exaust_emmision)

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


			# Boost start input
			if Input.is_action_pressed(inputs['buttons']["boost"]['control_string']) and accel_input != 0:
				apply_boost()

			# Boost stop input
			if Input.is_action_just_released(inputs['buttons']["boost"]['control_string']):
				stop_boost.emit()

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
		
		RaceState.FINISH:
			pass

# TODO
# add respawn confirmation hit box so cant return collision inside object
# Add wrong way detection
