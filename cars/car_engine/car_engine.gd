class_name CarEngine extends Node

signal emit_exaust()

@export var rpm_torque_curve: Curve
@export var torque_force_curve: Curve
@export var boost_multiplier: float


@export var max_boost_reserve: float = 100
@export var current_boost_reserve: float= 100.0
@export var boost_consumption_rate: float = 0.5

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

var is_boosting: bool = false
var boost_stength: float = 2.0

var boost_regen_rate_drive: float = 0.1
var boost_regen_rate_drift: float = 0.3


var torque_output: float = 0.0
var max_torque: int = 45000

var reverse_speed: float = 25068.25/2
var max_reverse_rpm: int = 1000

var power_output: float
var max_power_output: float = 25068.2

func _ready() -> void:
	get_parent().connect('start_boost', _inject_boost)
	get_parent().connect('stop_boost', _drop_boost)

# Engine
func _physics_process(delta: float) -> void:
	# Get acceleration strength and direction
	var accel_input = get_parent().accel_input
	# Handle moving forward
	if accel_input > 0:
		# If accelerating from reverse, set rpm to 0
		if current_gear == -1:
			current_rpm = 0
			current_gear = 1
		# Use accel input as valve manager to calculate car acceleration rate
		valve_influence = clampf(accel_input, 0, 1)
		# Calculate current rpm = previous rpm + additional rpm through accel input * gear acceleration 
		# Rpm can not go higher than max_rpm
		if !is_boosting:
			current_rpm = min(current_rpm + (valve_influence * acceleration * gear_acceleration_scale[current_gear]), max_rpm)
		else:
			current_rpm = current_rpm + (valve_influence * acceleration * gear_acceleration_scale[current_gear]) * boost_stength

	elif accel_input < 0:
		# Handle reverse movement
		if get_parent().linear_velocity.dot(-get_parent().transform.basis.z) <= 0.1 * 100:
			down_shift(true)
			current_gear = -1
			current_rpm = max_reverse_rpm * abs(accel_input)
			power_output = accel_input * reverse_speed
			$Control/Gear.text = 'current gear: ' + str('R')
			$Control/SPEED.text ='speed_output: ' + str(power_output)
			$Control/RPM.value = current_rpm
			return
		# Handle deceleration through braking
		else:
			current_rpm = max(current_rpm - deceleration_rate * (break_strength * abs(accel_input)), 0)
	
	# Handle no input decelearation
	else:
		# Handle natrual deceleration when car was last in reverse
		# UI to show reverse Reverse inputs
		if current_gear == -1:
			current_rpm = max(current_rpm - deceleration_rate, 0)
			power_output = calculate_power_output()

			$Control/Gear.text = 'current gear: ' + str('R')
			$Control/SPEED.text ='speed_output: ' + str(power_output)
			$Control/RPM.value = current_rpm
			return
		# Handle deceleration from any fowrward drive gears
		current_rpm = max(current_rpm - deceleration_rate, 0)
	
	# Handle gear shifting 
	if current_rpm >= max_rpm:
		up_shift()
	elif current_rpm <= min_rpm:
		down_shift()
	
	# Final power output when in drive
	power_output = calculate_power_output()

	# Handle boost regen
	if is_boosting:
		regen_boost(0)
		current_boost_reserve -= boost_consumption_rate
	else:
		if current_boost_reserve != max_boost_reserve:
			if get_parent().current_state == get_parent().State.DRIVE:
				current_boost_reserve = regen_boost(boost_regen_rate_drive)
				
			elif get_parent().current_state == get_parent().State.DRIFT:
				current_boost_reserve = regen_boost(boost_regen_rate_drift)
			else:
				
				current_boost_reserve = regen_boost(boost_regen_rate_drive)

	# Update Ui in drive
	$Control/Gear.text = 'current gear: ' + str(current_gear)
	$Control/SPEED.text ='speed_output: ' + str(power_output)
	$Control/RPM.value = current_rpm
	$Control/Boost.value = current_boost_reserve

# Return power output of current torque and gear ratios given current rpm
func calculate_power_output() -> float:
	var torque_output: int = rpm_torque_curve.sample(current_rpm)
	var gear_look_up:  int = current_gear if current_gear != gear_transition_points.size() else current_gear -1
	var gear_ratio: float = gear_transition_points[gear_look_up]
	return torque_force_curve.sample(torque_output) * gear_ratio

# Shift up a gear and signal exhaust to pop
func up_shift() -> void:
	# If at max gear, return
	if current_gear == gear_transition_points.size():
		return
	# Shift up a gear and set new rpm values
	else:
		current_gear += 1
		current_rpm -= rpm_loss
		emit_exaust.emit()

# Shift down a gear and signal exhaust to pop
func down_shift(in_reverse: bool = false) -> void:
	# If current gear is at 1 and rpm is below minimum rpm, return
	if current_gear == 1:
		return
	# Set gear to -1 (Reverse)
	if in_reverse:
		current_gear = -1
	# Shift down a gear 
	else:
		current_gear = max(current_gear -1, 1)
		current_rpm = max_rpm - rpm_loss
		emit_exaust.emit()

# Return percent of speed as max speed as float
func get_normalized_power_output() -> float:
	return power_output/max_power_output

# Inject engine with extra rpm if boost avalible
func _inject_boost() -> void:
	if current_boost_reserve > 0:
		is_boosting = true
	else:
		is_boosting = false

# Remove extra rmp
func _drop_boost() -> void:
	is_boosting = false

# Return boost + boost regen rate
func regen_boost(regen_rate: float) -> float:
	return clampf(current_boost_reserve + regen_rate, current_boost_reserve, max_boost_reserve)
