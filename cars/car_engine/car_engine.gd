class_name CarEngine extends Node

signal emit_exaust()

@export var engine_stat_resource: EngineStats

var rpm_torque_curve: Curve
var torque_force_curve: Curve
var boost_multiplier: float
var max_boost_reserve: float = 100
var boost_consumption_rate: float = 0.5
var boost_regen_rate_drive: float
var boost_regen_rate_drift: float
var max_power_output: float
var max_reverse_rpm: int
var reverse_speed: float
var break_strength: int
var boost_stength: float
var deceleration_rate: int
var acceleration: float
var min_rpm: int
var max_rpm: int
var gear_transition_points: Array[float]
var gear_acceleration_scale: Array[float]
var rpm_loss: int

# Realtime varibles
var current_gear: int = 1
var valve_influence: float = 0.0
var current_rpm: int = 0
var is_boosting: bool = false
var current_boost_reserve: float= 100.0
var in_countdown: bool = true

@export var mute: bool = true
# Output values
var torque_output: float = 0.0
var power_output: float

func _ready() -> void:
	get_parent().connect('start_boost', _inject_boost)
	get_parent().connect('stop_boost', _drop_boost)
	set_up_engine()

func set_up_engine() -> void:
	rpm_torque_curve = engine_stat_resource.rpm_torque_curve
	torque_force_curve = engine_stat_resource.torque_force_curve
	boost_multiplier = engine_stat_resource.boost_multiplier
	max_boost_reserve = engine_stat_resource.max_boost_reserve
	boost_consumption_rate = engine_stat_resource.boost_consumption_rate
	boost_regen_rate_drive = engine_stat_resource.boost_regen_rate_drive
	boost_regen_rate_drift = engine_stat_resource.boost_regen_rate_drift
	max_power_output = engine_stat_resource.max_power_output
	max_reverse_rpm = engine_stat_resource.max_reverse_rpm
	reverse_speed = engine_stat_resource.reverse_speed
	break_strength = engine_stat_resource.break_strength
	boost_stength = engine_stat_resource.boost_stength
	deceleration_rate = engine_stat_resource.deceleration_rate
	acceleration = engine_stat_resource.acceleration
	min_rpm = engine_stat_resource. min_rpm
	max_rpm = engine_stat_resource.max_rpm
	gear_transition_points = engine_stat_resource.gear_transition_points
	gear_acceleration_scale = engine_stat_resource.gear_acceleration_scale
	rpm_loss = engine_stat_resource.rpm_loss

# Engine
func _physics_process(delta: float) -> void:
	# Get acceleration strength and direction
	var accel_input = get_parent().accel_input
	
	if in_countdown:
		if accel_input > 0:
			valve_influence = clampf(accel_input, 0, 1)
			# Calculate current rpm = previous rpm + additional rpm through accel input * gear acceleration 
			current_rpm = current_rpm + (valve_influence * acceleration * gear_acceleration_scale[0]) * boost_stength
			if current_rpm >= max_rpm:
				current_rpm -= rpm_loss/4
				emit_exaust.emit()
		else:
			current_rpm = max(current_rpm - deceleration_rate, 0)
		# Update Ui in drive
		$CanvasLayer/Control/Gear.text = 'current gear: ' + str(current_gear)
		$CanvasLayer/Control/Speed.text = str(roundi(abs(get_parent().linear_velocity.dot(get_parent().transform.basis.z)*3.8))) +"  KMPH"
		$CanvasLayer/Control/RPM.value = current_rpm
		$CanvasLayer/Control/Boost.value = current_boost_reserve
	else:
		
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
				$CanvasLayer/Control/Gear.text = 'current gear: ' + str('R')
				$CanvasLayer/Control/Speed.text = str(roundi(abs(get_parent().linear_velocity.dot(get_parent().transform.basis.z)*3.8))) +"  KMPH"
				$CanvasLayer/Control/RPM.value = current_rpm
				$CanvasLayer/Control/Boost.value = current_boost_reserve
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

				$CanvasLayer/Control/Gear.text = 'current gear: ' + str('R')
				$CanvasLayer/Control/Speed.text = str(roundi(abs(get_parent().linear_velocity.dot(get_parent().transform.basis.z)*3.8))) +"  KMPH"
				$CanvasLayer/Control/RPM.value = current_rpm
				$CanvasLayer/Control/Boost.value = current_boost_reserve
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
		$CanvasLayer/Control/Gear.text = 'current gear: ' + str(current_gear)
		$CanvasLayer/Control/Speed.text = str(roundi(abs(get_parent().linear_velocity.dot(get_parent().transform.basis.z)*3.8))) +"  KMPH"
		$CanvasLayer/Control/RPM.value = current_rpm
		$CanvasLayer/Control/Boost.value = current_boost_reserve

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

func start_race() -> void:
	in_countdown = false
