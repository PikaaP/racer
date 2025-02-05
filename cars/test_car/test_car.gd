extends RigidBody3D


# force = (suspension_offset * spring_strength) | force the spring wishes to go to rest distance

# force = -(velocity * damping_stength) | dampanin force opposite direction of velocty

@export var top_speed: int = 100
var suspension_offset := 0.0
# force = (offset * spring_stength) - (velocity * damping_strength) | resultant of suspension_offset - damping_strength
var spring_force

var steer_input: float
var speed_input: float


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('reset'):
		get_tree().reload_current_scene()


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed('ui_accept'):
		global_position = Vector3(0 , 2.5, 0)
	
	steer_input = Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left')
	if steer_input != 0:
		$FrontLeftTire.set_rotation(Vector3(0, -steer_input,0))
		$FrontRightTire.set_rotation(Vector3(0, -steer_input,0))
	else:
		$FrontLeftTire.rotation = (Vector3(0,0,0))
		$FrontRightTire.rotation = (Vector3(0,0,0))
	speed_input = Input.get_action_strength('ui_up') - Input.get_action_strength('ui_down')
	
	if speed_input != 0:
		$BackLeftTire.can_accel = true
		$BackRightTire.can_accel = true
		apply_central_force(Vector3.FORWARD * speed_input * 100)
	else:
		$BackLeftTire.can_accel = false
		$BackRightTire.can_accel = false
#
func get_point_velocity (point :Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_transform.origin)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	print(state)
	
func traction():
	apply_central_force(-transform.basis.y * 10)
