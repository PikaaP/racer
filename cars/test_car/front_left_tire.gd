extends RayCast3D

@export var car_body: RigidBody3D
@export var tire_radius := 0.5
@export var use_as_traction: bool
@export var use_as_steering: bool

# force = (suspension_offset * spring_strength) | force the spring wishes to go to rest distance
@export var spring_stength := 2000
@export var suspension_rest_distance := 0.5

# force = -(velocity * damping_stength) | dampanin force opposite direction of velocty
@export var damping_strength := 500

# force = (offset * spring_stength) - (velocity * damping_strength) | resultant of suspension_offset - damping_strength
var spring_force: float
var suspension_offset := 0.0
var steer_dir: Vector3
var spring_direction: Vector3
var tire_velocity: Vector3
var spring_velocity

var grip_factor := 0.5
var tire_mass := 10
var can_steer: bool
var can_accel: bool

func _ready() -> void:
	target_position = Vector3(0, -tire_radius, 0)

func _physics_process(delta: float) -> void:
	if is_colliding():
		apply_suspension()
		#apply_steering(delta)
		if can_accel:
			apply_acceleration()
	
func apply_suspension() -> void:
		# Spring up vector orientation
		spring_direction = global_transform.basis.y

		# Spring up vector orientation
		tire_velocity = car_body.get_point_velocity(global_transform.origin)

		# Current spring offset
		suspension_offset = suspension_rest_distance - global_transform.origin.distance_to(get_collision_point())

		# Calculate veloctiy along spring direction
		spring_velocity = spring_direction.dot(tire_velocity)

		# Calculate the resultant force of the suspension force - dampening force
		spring_force = (suspension_offset * spring_stength) - (spring_velocity * damping_strength)

		# Apply force to car
		car_body.apply_force(Vector3.UP * spring_force, global_transform.origin)
		
		if name == 'FrontLeftTire':
			pass
			#
			#print(spring_direction, ' spring dir')
			#print(tire_velocity, ' tire vel')
			#print(suspension_offset, ' sus offset')
			#print(spring_velocity, ' spring vel')
			#print(spring_force, ' spring foce')
			#print(Vector3.UP * spring_force, global_transform.origin, ' applied force')

func apply_steering(delta: float) -> void:
	steer_dir = global_transform.basis.x
	
	tire_velocity = car_body.get_point_velocity(global_transform.origin)
	#print(tire_velocity, ' tire vel')

	# Tires velocity in steering direction
	var steering_velocity = tire_velocity.dot(car_body.steer_input * steer_dir)
	print(steering_velocity, ' steer vel')

	# The change in steering velocity to target, grip factor ranges from 0-1
	var target_velocity_change = -steering_velocity * 1
	
	# Transform change in velocity to acceleration=delta_v/time speed, the acceleration nessacary to change velocity by target_vel in 1 physis step
	var target_velocity = target_velocity_change/ delta
	
	# Apply force to car 
	car_body.apply_force(steer_dir * tire_mass * target_velocity, global_transform.origin)
	#print(steer_dir * tire_mass * target_velocity, ' appied force')

func apply_acceleration() -> void:
	var accel_direction: Vector3 = global_transform.basis.z * car_body.speed_input
	# Forward speed on the car (in the direction of driving)
	
	var car_speed = car_body.global_transform.basis.z.dot(car_body.linear_velocity)
	
	# Normalized speed
	var normalised_speed: float = absf(car_speed) / car_body.top_speed
	
	var available_torque = -10

	# Apply force to car
	car_body.apply_force(accel_direction * available_torque, global_transform.origin)
