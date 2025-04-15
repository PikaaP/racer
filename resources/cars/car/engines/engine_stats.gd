class_name EngineStats extends Resource

# Curves
@export var rpm_torque_curve: Curve
@export var torque_force_curve: Curve

# Boost variables
@export var boost_multiplier: float
@export var max_boost_reserve: float = 100
@export var boost_consumption_rate: float = 0.5
@export var boost_regen_rate_drive: float = 1.0
@export var boost_regen_rate_drift: float = 2.0

# Gear variables
@export var max_rpm: int = 9000
@export var min_rpm: int = 3000
@export var max_reverse_rpm: int = 1000
@export var rpm_loss: int = 3000


@export var gear_transition_points: Array[float] = [
	1/6.0,
	2/6.0,
	3/6.0,
	4/6.0,
	5/6.0,
	6/6.0,
]

@export var gear_acceleration_scale: Array[float] = [
	4,
	3,
	1.5,
	0.9,
	0.7,
	0.6,
	0.6,
]


# Engine power
@export var acceleration: float = 25
@export var deceleration_rate: int = 300
@export var boost_stength: float
@export var max_power_output: float = 25068.2
@export var reverse_speed: float = 25068.25/2

# Break_power
@export var break_strength: int
