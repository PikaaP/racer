class_name CustomWheel extends RayCast3D

@onready var drift_mesh = $DriftMesh
@onready var drift_smoke = $DriftSmoke

@export var use_as_traction: bool

var start_drift: bool = false
var is_drifting: bool = false
var car: Node
var grip: float


######## Suspension variables ########
var previous_spring_length: float = 0.0
var force_direction: Vector3

var collision_point: Vector3
var collision_distance: float

var offset: float
var current_spring_length: float
var spring_velocity: float

var spring_force: float
var dampener_force: float
var suspension_force: Vector3

var point: Vector3

######## Acceleration variables ########
var acceleration_direction: Vector3
var torque: float

######## Turning variables ########
var steer_direction: Vector3
var tire_velocity: Vector3
var lateral_velocity: float
var desired_velocity_change: float
var desired_acceleration: float
var steer_force: float
var minimum_drift_threshold: float = 3.0
var tire_mass: int = 10

######## Z Damp variables ########
var z_damp_direction: Vector3
var z_damp_force: float

# Drift smoke variables
var max_drift_smoke_amount: int = 500

func _ready() -> void:
	car = get_parent()
	target_position = Vector3(0, -car.car_stat_resource.wheel_radius, 0)


func _physics_process(delta: float) -> void:
	# Apply forces if colliding
	if is_colliding():
		# Get collision point
		collision_point = get_collision_point()

		# Find point to aplly spring force to
		point = Vector3(collision_point.x, collision_point.y + car.car_stat_resource.wheel_radius, collision_point.z)
		# Get tire velocity
		tire_velocity = get_point_velocity(global_position)
		
		# Always apply suspension and deceleration forces 
		# Apply suspension
		apply_suspension(delta)

		# Apply movement forces
		if car.current_race_state == car.RaceState.RACE:
			apply_acceleration(delta)
			apply_x_force(delta)
			# Slow down car if not actively accelerating
			#if car.accel_input == 0:
				#apply_z_force(delta)

func _process(delta: float) -> void:
	# Check if should draw mesh
	match car.current_race_state:
		car.RaceState.START:
			if car.accel_input != 0:
				if use_as_traction:
					drift_smoke.amount = ceil(abs(car.accel_input)) * max_drift_smoke_amount/4
					drift_smoke.lifetime = 2.0
					drift_smoke.emitting = true
			else:
				drift_smoke.emitting = false
		car.RaceState.RACE:
			if is_colliding() and abs(lateral_velocity) >= minimum_drift_threshold:
				if use_as_traction:
					drift_smoke.global_position = collision_point
					drift_smoke.emitting = true
				if !is_drifting:
					start_drift = true
					is_drifting = true
			else:
				if use_as_traction:
					drift_smoke.emitting = false
				is_drifting = false

# Control suspension
func apply_suspension(delta: float) -> void:
		# Add direction to apply force
		force_direction = global_basis.y
		collision_distance = collision_point.distance_to(global_position)

		# Calculate spring offset from rest position
		offset =  car.car_stat_resource.spring_rest_distance - collision_distance
		current_spring_length = clamp(car.car_stat_resource.spring_rest_distance - offset, 0, car.car_stat_resource.spring_rest_distance)
		
		# Find change in spring velocity
		spring_velocity = (previous_spring_length - current_spring_length) / delta
		
		# Calculate spring force
		
		var upper = 1
		var spring_mulit = 1
		var damp_multi = 0.5
		
		spring_force = offset * car.car_stat_resource.spring_strength * spring_mulit
		# Calculate dampener force
		dampener_force = spring_velocity * car.car_stat_resource.spring_dampener_strength * damp_multi
		# Calculate total suspension force
		suspension_force = basis.y * (clamp(spring_force + dampener_force, -car.car_stat_resource.max_spring_strength * upper, car.car_stat_resource.max_spring_strength * upper))

		# Store new spring length value
		previous_spring_length = current_spring_length

		# Apply force to car :D
		car.apply_force(suspension_force * force_direction, point - car.global_position)

# Control drive train
func apply_acceleration(delta) -> void:
	# Only apply traction if set in car drive train
	if not use_as_traction:
		return

	# Get direction to apply force
	acceleration_direction = -global_basis.z

	# Accelerate by avalible torque
	torque = car.get_torque(car.normalized_speed) * (car.accel_input * car.car_stat_resource.max_torque) if car.current_state != car.State.NEUTRAL else car.get_torque(car.normalized_speed) * (car.accel_input * car.car_stat_resource.max_torque * 2)

	if car.current_boost_multiplier!= 1.0:
		torque += car.car_stat_resource.max_torque/2 * car.current_boost_multiplier


	# Apply force to car :D
	car.apply_force(acceleration_direction * torque, point - car.global_position)
	

# Control steering
func apply_x_force(delta) -> void:
	#var collision_point = get_collision_point()
	#var point = Vector3(collision_point.x, collision_point.y + car.car_stat_resource.wheel_radius, collision_point.z)

	# Get horizontal axis
	steer_direction =  global_basis.x

	# Calculate velocity in the sliding direction (opposite to steering)
	lateral_velocity = steer_direction.dot(tire_velocity)

	# Scale steering direction velocity grip, (grip value is between [0,1])
	# Increase desired velocity if car is in neutral state
	if use_as_traction:
		desired_velocity_change = -lateral_velocity * car.get_tire_grip(true) if car.current_state != car.State.DRIFT else -lateral_velocity * car.get_tire_grip(true) /3
	else:
		desired_velocity_change = -lateral_velocity * car.get_tire_grip() if car.current_state != car.State.DRIFT else -lateral_velocity * car.get_tire_grip(true) /3.1

	# Calculate target acceleration
	desired_acceleration = desired_velocity_change/delta

	# Multplily accelration by mass value to get force, TODO
	steer_force = desired_acceleration * tire_mass * 3

	# Apply force to car :D
	car.apply_force(steer_direction * steer_force, point - car.global_position)

	# Add force in opposite direction of steering to simulate drifting
	if car.current_state == car.State.DRIFT:
		car.apply_force(steer_direction * -(car.speed * car.accel_input) * car.steer_input, point - car.global_position)

		# Transition out of drift if drift force is low
		if abs(lateral_velocity) < minimum_drift_threshold:
			car.current_state = car.State.DRIVE

# Control velocity.z dampening 
func apply_z_force(delta):
	z_damp_direction = global_basis.z
	z_damp_force = z_damp_direction.dot(tire_velocity) * car.mass/8
	car.apply_force(-z_damp_direction * z_damp_force, collision_point - car.global_position)

# Get velocity at a single point in world space
func get_point_velocity(point: Vector3) -> Vector3:
	return car.linear_velocity + car.angular_velocity.cross(point - car.global_position)
