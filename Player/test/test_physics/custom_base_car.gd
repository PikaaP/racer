class_name CustomCar extends RigidBody3D

# Custom wheels
@onready var fl_wheel = $FrontRightWheel
@onready var fr_wheel = $FrontLeftWheel
@onready var bl_wheel = $BackLeftWheel
@onready var br_wheel = $BackRightWheel

# Wheel textures
@onready var fr_wheel_visual = $FrontRightWheel/Wheel
@onready var fl_wheel_visual = $FrontLeftWheel/Wheel
@onready var bl_wheel_visual = $BackLeftWheel/Wheel
@onready var br_wheel_visual = $BackRightWheel/Wheel

@export var spring_rest_distance: = 0.8
@export var wheel_radius: float = 0.9
@export var spring_strength: int = 6000
@export var spring_dampener_strength: float = 350
@export var front_grip: float = 1.0
@export var rear_grip: float = 0.75

@export var max_spring_strength: int = spring_strength + 200

@export var tire_grip: float = 1
@export var steering_angle: int = 30
@export var steer_speed: float = 1.5

var accel_input: int
var steer_input: int

@export var fr_visual_start_position: Vector3 = Vector3(-0.058,-0.259, 0.034)
@export var fl_visual_start_position: Vector3 = Vector3(0.11,-0.259, 0.027)
@export var br_visual_start_position: Vector3 = Vector3(0.0,-0.259, -0.043)
@export var bl_visual_start_position: Vector3 = Vector3(0.015,-0.259, -0.043)




func _ready() -> void:
	fl_wheel.grip = front_grip
	fr_wheel.grip = front_grip
	bl_wheel.grip = rear_grip
	br_wheel.grip = rear_grip
	
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	# Get player inputs
	accel_input = Input.get_action_strength('ui_up') - Input.get_action_strength('ui_down')
	steer_input = Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left')

	# Control steering
	steering(delta)
	# Update wheel visuals
	wheel_visuals(delta)

# Apply traction
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	apply_central_force(Vector3.DOWN * 300)

# Adjust wheel height and spin based on velocity 
func wheel_visuals(delta) -> void:
	# Move wheel position in accordance to suspension offset
	fr_wheel_visual.position.y = move_toward(fl_wheel_visual.position.y, clampf(fr_visual_start_position.y + fr_wheel.offset, -spring_rest_distance, spring_rest_distance) , delta)
	fl_wheel_visual.position.y = move_toward(fl_wheel_visual.position.y, clampf(fl_visual_start_position.y + fl_wheel.offset, -spring_rest_distance, spring_rest_distance) , delta)
	br_wheel_visual.position.y = move_toward(fl_wheel_visual.position.y, clampf(br_visual_start_position.y + br_wheel.offset, -spring_rest_distance, spring_rest_distance) , delta)
	bl_wheel_visual.position.y = move_toward(fl_wheel_visual.position.y, clampf(bl_visual_start_position.y + bl_wheel.offset, -spring_rest_distance, spring_rest_distance) , delta)
	
	# Spin wheels when moving :D
	fr_wheel_visual.rotation_degrees.x += linear_velocity.length()*Engine.get_frames_per_second()*delta
	fl_wheel_visual.rotation_degrees.x += linear_velocity.length()*Engine.get_frames_per_second()*delta
	br_wheel_visual.rotation_degrees.x += linear_velocity.length()*Engine.get_frames_per_second()*delta
	bl_wheel_visual.rotation_degrees.x += linear_velocity.length()*Engine.get_frames_per_second()*delta
	
	
# Control steering for front wheels
func steering(delta: float) -> void:
	var steer_rotation = -steer_input * steering_angle
	
	if steer_rotation != 0:
		var angle = clamp(fl_wheel.rotation.y + steer_rotation, -steering_angle, steering_angle)
		var new_rotation = angle * delta
		fl_wheel.rotation.y = move_toward(fl_wheel.rotation.y, new_rotation, steer_speed * delta)
		fr_wheel.rotation.y = move_toward(fl_wheel.rotation.y, new_rotation, steer_speed * delta)

	else:
		fl_wheel.rotation.y = move_toward(fl_wheel.rotation.y, 0.0, steer_speed * delta)
		fr_wheel.rotation.y = move_toward(fl_wheel.rotation.y, 0.0, steer_speed * delta)

# Return torque value from torque graph
func get_torque() -> int:
	return 600
