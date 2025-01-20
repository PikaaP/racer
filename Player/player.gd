extends VehicleBody3D


@export var STEER_SPEED = 3
@export var STEER_LIMIT = 0.8

@export var engine_force_value = 1000
@export var early_accel_lmit := 1000

var steer_target = 0

func _physics_process(delta):
	var speed = linear_velocity.length() *delta
	traction(speed)
	#$Hud/speed.text=str(round(speed*3.8))+"  KMPH"

	var fwd_mps = transform.basis.x.x
	steer_target = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	steer_target *= STEER_LIMIT

	if steer_target > 0:
		apply_torque(Vector3.RIGHT*speed)
	else:
		apply_torque(Vector3.LEFT*speed)
	
	if Input.is_action_pressed("ui_down"):
	# Increase engine force at low speeds to make the initial acceleration faster.
		if speed < 20 and speed != 0:
			engine_force = -clamp(engine_force_value * 3 / speed, 0, early_accel_lmit)
		else:
			engine_force = engine_force_value
	else:
		pass
		#engine_force = 0

	if Input.is_action_pressed("ui_up"):
		# Increase engine force at low speeds to make the initial acceleration faster.
		if fwd_mps >= -1:
			if speed < 0.2 and speed != 0:
				engine_force = clamp(engine_force_value * 10 / speed, 0, early_accel_lmit)
			else:
				print(engine_force_value, ' why 50')
				engine_force  = engine_force_value
				print(engine_force, ' engine foce')
		else:
			brake = 1
	else:
		brake = 0.0
		
	if Input.is_action_pressed("ui_select"):
		brake= 0.0
		$BackLeft.wheel_friction_slip=0.8
		$BackRight.wheel_friction_slip=0.8
	else:
		$BackLeft.wheel_friction_slip=3
		$BackRight.wheel_friction_slip=3

	steering = move_toward(steering, steer_target, STEER_SPEED * 20 * delta)

func traction(speed):
	apply_central_force(Vector3.DOWN*speed * 100)
