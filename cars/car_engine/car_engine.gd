class_name CarEngine extends Node

signal emit_exaust()

var valve_influence: float = 0.0
var current_gear: int = 1

var gear_transition_points: Array[float] = [
	1/6.0,
	2/6.0,
	3/6.0,
	4/6.0,
	5/6.0,
	6/6.0,
]

var gear_acceleration_scale: Array[float] = [
	4,
	3,
	1.5,
	0.9,
	0.7,
	0.6,
	0.6,
]

var rpm_loss: int = 3000
var current_rpm: int = 0
var min_rpm: int = 3000
var max_rpm: int = 9000
var acceleration: float = 25
var deceleration_rate: int = 300
var break_strength: int = 2


@export var rpm_torque_curve: Curve
@export var torque_force_curve: Curve

var torque_output: float = 0.0
var max_torque: int = 45000
var max_speed: int = 240
var reverse_speed: float = 25068.25/2

var power_output: float

func _physics_process(delta: float) -> void:
	var accel_input = get_parent().accel_input
	if get_parent().linear_velocity.dot(-get_parent().transform.basis.z) <= 0.1:
		if accel_input < 0:
			#print('in rev')
			current_gear = 1
			power_output = accel_input * reverse_speed
			current_rpm = 10000 * accel_input
			$Control/Gear.text = 'current gear: ' + 'R'
			$Control/SPEED.text ='speed_output: ' + str(power_output)
			$Control/RPM.value = current_rpm
			return
		elif accel_input == 0:
			#print('maybe going neutral neutral here')
			current_rpm = clamp(current_rpm - deceleration_rate, 0, max_rpm)
			#print(current_rpm)
			if current_rpm >= max_rpm:
				up_shift()
			elif current_rpm <= min_rpm:
				down_shift()
			
			var gear_look_up:  int = current_gear if current_gear != gear_transition_points.size() else current_gear- 1
			var gear_ratio: float = gear_transition_points[gear_look_up]
			power_output = torque_force_curve.sample(torque_output) * gear_ratio
		else:
			#print('in drive plz 2')
			valve_influence = clampf(accel_input, 0, 1)
			if valve_influence <= 0:
				current_rpm = clamp(current_rpm - deceleration_rate, 0, max_rpm)
			else:
				current_rpm = clamp(current_rpm + (valve_influence * acceleration * gear_acceleration_scale[current_gear]), 0, max_rpm)
			
			if current_rpm >= max_rpm:
				up_shift()
			elif current_rpm <= min_rpm:
				down_shift()
			
			var gear_look_up:  int = current_gear if current_gear != gear_transition_points.size() else current_gear- 1
			var gear_ratio: float = gear_transition_points[gear_look_up]
			
			var torque_output: int = rpm_torque_curve.sample(current_rpm)
			power_output = torque_force_curve.sample(torque_output) * gear_ratio
	else:
		#print('in drive plz')
		valve_influence = clampf(accel_input, 0, 1)
		if valve_influence <= 0:
			current_rpm = clamp(current_rpm - deceleration_rate, 0, max_rpm)
		else:
			current_rpm = clamp(current_rpm + (valve_influence * acceleration * gear_acceleration_scale[current_gear]), 0, max_rpm)
		
		if current_rpm >= max_rpm:
			up_shift()
		elif current_rpm <= min_rpm:
			down_shift()
		
		var gear_look_up:  int = current_gear if current_gear != gear_transition_points.size() else current_gear- 1
		var gear_ratio: float = gear_transition_points[gear_look_up]
		
		var torque_output: int = rpm_torque_curve.sample(current_rpm)
		power_output = torque_force_curve.sample(torque_output) * gear_ratio
	
	$Control/Gear.text = 'current gear: ' + str(current_gear)
	$Control/SPEED.text ='speed_output: ' + str(power_output)
	$Control/RPM.value = current_rpm

func up_shift() -> void:
	if current_gear == gear_transition_points.size():
		print('max gear')
		return
	else:
		print('shift up')
		current_gear += 1
		current_rpm -= rpm_loss
		emit_exaust.emit()

	print('Current gear up to: ',current_gear)

func down_shift() -> void:
	if current_gear == 1:
		if current_rpm == 0:
			pass
	else:
		current_gear = max(current_gear -1, 1)
		current_rpm = max_rpm - 1000
		emit_exaust.emit()
		
		print('Current gear down to: ',current_gear)
