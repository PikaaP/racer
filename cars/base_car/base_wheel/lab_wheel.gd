extends RayCast3D

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
var acceleration_force: float

######## Turning variables ########
var steer_direction: Vector3
var tire_velocity: Vector3
var lateral_velocity: float
var desired_velocity_change: float
var desired_acceleration: float
var steer_force: float
var minimum_drift_threshold: float = 1.0
var tire_mass: int = 8

######## Z Damp variables ########
var z_damp_direction: Vector3
var z_damp_force: float

# Drift smoke variables
var max_drift_smoke_amount: int = 500

var transition_out_of_drift: bool = false

func _ready() -> void:
	car = get_parent()
	target_position = Vector3(0, -car.car_stat_resource.wheel_radius, 0)

func _physics_process(delta: float) -> void:
	# Manually update raycast detection
	force_raycast_update()

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
			if car.accel_input == 0 and !is_zero_approx(car.linear_velocity.z):
				apply_z_force(delta)
	else:
		return_suspension()

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
			if is_colliding() and abs(lateral_velocity) >= 100:
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
		# Find direction to apply force
		force_direction = global_basis.y
		collision_distance = collision_point.distance_to(global_position)

		# Calculate spring offset from rest position
		offset =  car.car_stat_resource.spring_rest_distance - collision_distance
		current_spring_length = clamp(car.car_stat_resource.spring_rest_distance - offset, 0, car.car_stat_resource.spring_rest_distance)
		
		# Find change in spring velocity
		spring_velocity = force_direction.dot(tire_velocity)

		# Calculate spring force
		spring_force = offset * car.car_stat_resource.spring_strength

		# Calculate dampener force
		dampener_force = -(spring_velocity * car.car_stat_resource.spring_dampener_strength)

		# Calculate total suspension force
		suspension_force = basis.y * (spring_force + dampener_force)
		
		# Store new spring length value
		previous_spring_length = current_spring_length

		# Apply force to car :D
		car.apply_force(suspension_force/2 * force_direction, point - car.global_position)

		draw_arrow(global_position, force_direction, suspension_force.y/1000, 'sus', Color.BLACK)

# Control drive train
func apply_acceleration(delta) -> void:
	# Only apply traction if set in car drive train
	if not use_as_traction:
		return

	# Get direction to apply force
	acceleration_direction = -global_basis.z

	# Accelerate by avalible torque
	acceleration_force = car.get_engine_power()
	
	draw_arrow(global_position, (acceleration_direction * acceleration_force).normalized(), abs(car.normalized_speed * 10), 'z', Color.GOLD)
	
	# Apply force to car :D
	car.apply_force(acceleration_direction * acceleration_force, point - car.global_position)

# Control steering
func apply_x_force(delta) -> void:
	# Get horizontal axis
	steer_direction = global_basis.x

	# Calculate velocity in the sliding direction (opposite to steering)
	lateral_velocity = steer_direction.dot(tire_velocity)
	
	# Scale steering direction velocity by grip, (grip value is between [0,1])
	if use_as_traction:
		if car.current_state != car.State.DRIFT:
			if transition_out_of_drift:
				desired_velocity_change = lerpf(desired_velocity_change, -lateral_velocity, delta)
				if name == 'BackRightWheel':
					#print('iREVOERY')
					pass
			else:
				if name == 'BackRightWheel':
					pass
					#print('drift revoery over')
				desired_velocity_change = -lateral_velocity
			
			if abs(desired_velocity_change- lateral_velocity) <= 0.1:
				transition_out_of_drift = false

		else:
			desired_velocity_change = -lateral_velocity/5
			if name == 'BackRightWheel':
				pass
				#print('is drifting')

	else:
		if car.current_state != car.State.DRIFT:
			if transition_out_of_drift:
				desired_velocity_change = lerpf(desired_velocity_change, -lateral_velocity, delta)
			else:
				desired_velocity_change = -lateral_velocity
			
			if abs(desired_velocity_change - lateral_velocity) <= 0.1:
				transition_out_of_drift = false

		else:
			desired_velocity_change = -lateral_velocity/6




	# Calculate target acceleration
	desired_acceleration = desired_velocity_change/delta

	#steer_force = desired_acceleration * tire_mass
	steer_force = desired_acceleration * 50

	draw_arrow(global_position, steer_direction * lateral_velocity, steer_force/1000, 'x_drift', Color.REBECCA_PURPLE)
	draw_arrow(global_position, steer_direction * lateral_velocity, steer_force/1000, 'x_steer', Color.ROYAL_BLUE)

	# Apply force to car :D
	car.apply_force(steer_direction * steer_force, point - car.global_position)

	# Add force in opposite direction of steering to simulate drifting
	if car.current_state == car.State.DRIFT:
		car.apply_force(steer_direction * -(car.speed * 100 * car.accel_input) * car.steer_input, point - car.global_position)

		# Transition out of drift if drift force is low
		if abs(lateral_velocity) < minimum_drift_threshold:
			car.current_state = car.State.DRIVE
			transition_out_of_drift = true

# Control velocity.z dampening 
func apply_z_force(delta):
	z_damp_direction = global_basis.z
	z_damp_force = z_damp_direction.dot(tire_velocity) * car.mass/4
	
	draw_arrow(global_position, -z_damp_direction * z_damp_direction.dot(tire_velocity), z_damp_force, 'z_damp', Color.CHARTREUSE)

	car.apply_force(-z_damp_direction * z_damp_force, collision_point - car.global_position)

func return_suspension() -> void:
	# Find direction to apply force
	force_direction = global_basis.y
	collision_distance = car.car_stat_resource.wheel_radius

	# Calculate spring offset from rest position
	offset =  car.car_stat_resource.spring_rest_distance - collision_distance
	current_spring_length = clamp(car.car_stat_resource.spring_rest_distance - offset, 0, car.car_stat_resource.spring_rest_distance)
	
	# Store new spring length value
	previous_spring_length = current_spring_length

# Get velocity at a single point in world space
func get_point_velocity(global_point: Vector3) -> Vector3:
	return car.linear_velocity + car.angular_velocity.cross(global_point - car.global_position)


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
