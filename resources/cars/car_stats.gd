class_name CarStats extends Resource

# Suspesion stats
@export var spring_strength: int = 6000
@export var max_spring_strength: int = spring_strength + 200
@export var spring_rest_distance: = 0.8
@export var spring_dampener_strength: float = 350

# Wheel stats
@export var tire_grip_curve: Curve
@export var wheel_radius: float = 0.9
@export var front_grip: float = 1.0
@export var rear_grip: float = 1.0
@export var front_grip_curve: Curve
@export var rear_grip_curve: Curve


# Steering stats
@export var steering_angle: int = 30
@export var steer_speed: float = 1.5
@export var steer_limit: float = 0.8

# Car properties
@export var mass: float = 80.0

# Engine stats
@export var max_speed: float = 28.0
@export var torque_curve: Curve
@export var max_torque: float = 1000.0
