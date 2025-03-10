class_name BotWheel extends RayCast3D

@onready var drift_mesh = $DriftMesh

@export var car: Bot2
@export var use_as_traction: bool
@export_range(0.0, 1, 0.01) var grip: float
@export var is_drifting: bool = false

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

######## Z Damp variables ########
var z_damp_direction: Vector3
var z_damp_force: float

var start_drift: bool = false
var drift_mesh_threshold: float = 3.0

func _ready() -> void:
	target_position = Vector3(0, -car.car_stat_resource.wheel_radius, 0)

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		if is_colliding():
			collision_point = get_collision_point()

			# Find point to aplly spring force to
			point = Vector3(collision_point.x, collision_point.y + car.car_stat_resource.wheel_radius, collision_point.z)
			# Get tire velocity
			tire_velocity = get_point_velocity(global_position)
			
			# Always apply suspension and deceleration forces 
			# Apply suspension
			apply_suspension(delta)

			# Slow down car if not actively accelerating
			if car.accel_input == 0:
				apply_z_force(delta)

			# Apply movement forces
			if car.can_move:
				apply_acceleration(delta)
				apply_x_force(delta)


func _process(delta: float) -> void:
	if abs(lateral_velocity) >= 0.1:
		if !is_drifting:
			start_drift = true
			is_drifting = true
	else:
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
		spring_force = offset * car.car_stat_resource.spring_strength
		
		# Calculate dampener force
		dampener_force = spring_velocity * car.car_stat_resource.spring_dampener_strength
		
		# Calculate total suspension force
		suspension_force = basis.y * (clamp(spring_force + dampener_force, -car.car_stat_resource.max_spring_strength, car.car_stat_resource.max_spring_strength))

		# Store new spring length value
		previous_spring_length = current_spring_length

		#DebugDraw3D.draw_arrow_ray(global_position, Vector3(0, suspension_force.y, 0).normalized(), suspension_force.y/100)

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
	torque = car.get_torque(car.normalized_speed) * (car.accel_input * car.car_stat_resource.max_torque)
	# Apply force to car :D
	car.apply_force(acceleration_direction * torque, point - car.global_position)

	#DebugDraw3D.draw_arrow_ray(global_position, acceleration_direction, torque/10, Color.DARK_ORCHID)

# Control steering
func apply_x_force(delta) -> void:
	var collision_point = get_collision_point()
	var point = Vector3(collision_point.x, collision_point.y + car.car_stat_resource.wheel_radius, collision_point.z)
	
	# Get horizontal axis
	steer_direction = global_basis.x

	# Calculate velocity in the sliding direction (opposite to steering)
	lateral_velocity = steer_direction.dot(tire_velocity)

	# Scale steering direction velocity grip, (grip value is between [0,1])
	if use_as_traction:
		desired_velocity_change = -lateral_velocity * car.get_tire_grip(true)
	else:
		desired_velocity_change = -lateral_velocity * car.get_tire_grip()
	
	
	# Calculate target acceleration
	desired_acceleration = desired_velocity_change/delta

	# Multplily accelration by mass value to get force, TODO
	steer_force = desired_acceleration

	# Apply force to car :D
	car.apply_force(steer_direction * steer_force, point - car.global_position)

	#DebugDraw3D.draw_arrow_ray(global_position, Vector3(desired_velocity_change * steer_force, 0, 0).normalized(), steer_force/20 , Color.GOLD)

# Control velocity.z dampening 
func apply_z_force(delta):
	z_damp_direction = global_basis.z
	z_damp_force = z_damp_direction.dot(tire_velocity) * car.mass/5
	
	car.apply_force(-z_damp_direction * z_damp_force, collision_point - car.global_position)

	#DebugDraw3D.draw_arrow_ray(global_position, -z_damp_direction, z_damp_force/10 , Color.CRIMSON)

# Get velocity at a single point in world space
func get_point_velocity(point: Vector3) -> Vector3:
	return car.linear_velocity + car.angular_velocity.cross(point - car.global_position)
