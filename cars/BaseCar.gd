extends VehicleBody3D


@export var STEER_SPEED = 1.5
@export var STEER_LIMIT = 0.6
@export var engine_force_value = 40
@export var drift_recovery_time = 0.8
var steer_target = 0


func _physics_process(delta):
	var speed = linear_velocity.length()*Engine.get_frames_per_second()*delta
	traction(speed)
	$Hud/speed.text=str(round(speed*3.8))+"  KMPH"

	var fwd_mps = transform.basis.x.x
	steer_target = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	steer_target *= STEER_LIMIT
	if steer_target != 0:
		apply_force(Vector3.FORWARD * speed * (1+ abs(steer_target)))
	if Input.is_action_pressed("ui_down"):
	# Increase engine force at low speeds to make the initial acceleration faster.

		if speed < 20 and speed != 0:
			engine_force = clamp(engine_force_value * 3 / speed, 0, 300)
		else:
			engine_force = engine_force_value
	else:
		engine_force = 0
	if Input.is_action_pressed("ui_up"):
		# Increase engine force at low speeds to make the initial acceleration faster.
		if fwd_mps >= -1:
			if speed < 30 and speed != 0:
				engine_force = -clamp(engine_force_value * 10 / speed, 0, 300)
			else:
				engine_force  = -engine_force_value
		else:
			brake = 1
	else:
		brake = 0.0
		
	if Input.is_action_pressed("ui_select"):
		$wheal0.wheel_friction_slip=0.9
		$wheal1.wheel_friction_slip=0.9
		$wheal2.wheel_friction_slip=0.8
		$wheal3.wheel_friction_slip=0.8
	else:
		$wheal0.wheel_friction_slip= min(4.1,$wheal0.wheel_friction_slip + delta* drift_recovery_time * abs(1 -steer_target) )
		$wheal1.wheel_friction_slip= min(4.1,$wheal1.wheel_friction_slip + delta* drift_recovery_time * abs(1-steer_target) )
		$wheal2.wheel_friction_slip= min(4.0,$wheal2.wheel_friction_slip + delta* drift_recovery_time * abs(1-steer_target) )
		$wheal3.wheel_friction_slip= min(4.0,$wheal3.wheel_friction_slip + delta* drift_recovery_time * abs(1-steer_target) )
		
		print($wheal0.wheel_friction_slip)
	steering = move_toward(steering, steer_target, STEER_SPEED * delta * drift_recovery_time)



func traction(speed):
	apply_central_force(Vector3.DOWN*speed * 10)
