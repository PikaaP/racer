class_name Bot2 extends VehicleBody3D

signal win(bot: Bot)
@export var car_stat_resource: CarStats

# Car function variables
@export var start_position: Vector3

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
@export var path_follow: PathFollow3D
@export var path: Path3D


@export var num_rays = 16
@export var ray_length := 5
@export var look_out_range := 2
@export var bot_avoidance := 0.5

@export var max_lap_count := 2
@export var current_checkpoint : int
@export var target_checkpoint: int
@export var current_lap: int

var intrest_array = []
var danger_array = []
var ray_directions = []
var next_path_point: Vector3

var velocity = Vector3.ZERO
var points_index = 0
var desired_velocity: Vector3
var points: PackedVector3Array
var sample_rate: int = 2
var steer_target = 0
var max_dist: int = 0
var min_dist: int = 10

var chosen_direction: Vector3
var respawning := false

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

func _process(delta: float) -> void:
	if not respawning:
		if global_position.distance_to(next_path_point) <= min_dist or points_index == 0 or global_position.distance_to(next_path_point) > max_dist:
			set_intrests()
			set_danger()
			choose_direction()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	apply_central_force(-transform.basis.y * 1000 * abs(linear_velocity.z))
	desired_velocity = chosen_direction
	desired_velocity.y = 0.0
	
	linear_velocity = desired_velocity * car_stat_resource.max_speed
	look_at(next_path_point)

# Set intrest direction based on world direction and target direction
func set_intrests() -> void:
	# Use new sample index to find next path point target
	points_index += sample_rate
	if points_index >= points.size():
		points_index = sample_rate

	# Set new path point and covert to global coordinates
	next_path_point = points[points_index] * path.scale

	$Sprite3D.global_position = next_path_point
	
	# Get direction to closest point
	var target_direction = global_position.direction_to(next_path_point)
	max_dist = global_position.distance_to(next_path_point)

	for i in num_rays:
		var d = ray_directions[i].dot(target_direction * global_position.distance_to(next_path_point))
		intrest_array[i] = max(0, d)

# Cast a ray in each direction. If there’s a hit, we add a 1 in that spot.
func set_danger() -> void:
	var space_state = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D
	var result: Dictionary
	
	# Priorites forward direction when looking for danger
	for i in num_rays:
		var angle = i * 2 * PI / num_rays
		# Forward facing rays are longer
		if rad_to_deg(angle)< 90  or rad_to_deg(angle)> 270:
			query = PhysicsRayQueryParameters3D.create(ray_holder.global_position, ray_holder.global_position + ray_directions[i] * 10, pow(2, 1-1) + pow(2, 4-1), [self])
		else:
			query = PhysicsRayQueryParameters3D.create(ray_holder.global_position, ray_holder.global_position + ray_directions[i] * 10, pow(2, 1-1) + pow(2, 4-1), [self])

		result = space_state.intersect_ray(query)
		if !result.is_empty():
			if result.collider.is_in_group('obstacle'):
				danger_array[i] = 0.0
			elif result.collider.is_in_group('player'):
				danger_array[i] = 0.5
			elif result.collider.is_in_group('bot'):
				danger_array[i] = bot_avoidance
		else:
			danger_array[i] = 1

# Finalise current direction vector 
func choose_direction() -> void:
	# Reset chosen direction
	chosen_direction = Vector3.ZERO

	# Eliminate intrest array if danger array exits at index
	for i in num_rays:
		intrest_array[i] *= danger_array[i]
		chosen_direction += ray_directions[i] * intrest_array[i]

	chosen_direction = chosen_direction.normalized()

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
		danger_array[i] = 0
		
		# Set decision ray distance and rotation
		ray.target_position = Vector3(0, 0, -ray_length)
		ray.rotate(Vector3.UP, angle)
		
		# Store ray direction in ray_directions array
		ray_directions.append(Vector3.FORWARD.rotated(Vector3.UP, angle))
		
		# Add ray as child of Bot/ray_holder
		ray_holder.add_child(ray)
	
