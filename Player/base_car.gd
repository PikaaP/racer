class_name PlayerCar extends VehicleBody3D

signal win(player: PlayerCar)

@onready var ground_ray: RayCast3D = $GroundRay
@onready var respawn_timer: Timer = $RespawnTimer
@onready var engine_sound = $EngineSound

@export var checkpoint_array = []
@export var current_checkpoint: int = 0
@export var target_checkpoint: int = 0
@export var current_lap: int = 0
@export var max_lap_count: int

@export var inputs = {}
@export var player_index: int 
@export var camera: PlayerCamera

@export var car_resource: CarStats
@export var STEER_SPEED: float = 2.5
@export var STEER_LIMIT = 0.8
@export var engine_force_value = 200
@export var max_drift_recovery_time: float = 2.0
@export var car_mass := 80.0
@export var max_speed := 200

var steer_target: float
var speed_input: float
var drift_recovery_time = 0
var speed = 0
var w_0 = 0
var w_b = 0
var drift_recovery = false
var respawning = false

func _ready() -> void:
	$Label3D.text = 'Current CHeck %s \n target: %s \n %s' % [str(current_checkpoint), str(target_checkpoint), str(current_lap)]
	respawn_timer.timeout.connect(_handle_respawn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('reset'):
		get_tree().reload_current_scene()

func _physics_process(delta):
	if not respawning:
		ground_ray.global_position = global_position
		speed = linear_velocity.length()*Engine.get_frames_per_second()*delta
		traction(speed)

		steer_target = Input.get_action_strength(inputs['motions']['left']['control_string']) - Input.get_action_strength(inputs['motions']['right']['control_string'])
		steer_target *= STEER_LIMIT
		speed_input = (Input.get_action_strength(inputs['motions']['up']['control_string']) - Input.get_action_strength(inputs['motions']['down']['control_string'])) * engine_force_value
		$wheel_2.engine_force = speed_input
		$wheel_3.engine_force = speed_input

		if drift_recovery:
			w_0 += delta 
			w_b += delta

			$wheel_0.wheel_friction_slip = lerpf($wheel_0.wheel_friction_slip, 1.2, w_0/1.2)
			$wheel_1.wheel_friction_slip = lerpf($wheel_1.wheel_friction_slip, 1.2, w_0/1.2)
			$wheel_2.wheel_friction_slip = lerpf($wheel_2.wheel_friction_slip, 1.15, w_0/1.15)
			$wheel_3.wheel_friction_slip = lerpf($wheel_3.wheel_friction_slip, 1.15, w_0/1.15)

			if w_0 > 1.2 and w_b > 1.15:
				drift_recovery = false
				w_0 = 0
				w_b = 0
		else:

			var tor = get_constant_torque() if get_constant_torque().length() < 2000 else Vector3(0, 100 * STEER_LIMIT + (100 * (1-abs(STEER_LIMIT))), 0)
			set_constant_torque(tor)

		if Input.is_action_pressed(inputs['buttons']["drift"]['control_string']):
			drift_recovery =  false
			add_constant_torque(Vector3(0, 30 * steer_target, 0))
			$wheel_0.wheel_friction_slip = 1.1
			$wheel_1.wheel_friction_slip = 1.1
			$wheel_2.wheel_friction_slip = 0.65
			$wheel_3.wheel_friction_slip = 0.65

		if Input.is_action_just_released(inputs['buttons']["drift"]['control_string']):
			drift_recovery =  true
			constant_torque = Vector3(0, 0, 0)
			constant_force = Vector3.ZERO

		if $wheel_3.get_skidinfo() <= 0.5:
			pass
		
		if  Input.is_action_just_pressed(inputs['motions']['up']['control_string']):
			$CarModel/BackLight.visible = true
			$CarModel/BackLight2.visible = true
			$"CarModel/Sketchfab_model/root/CarMesh/Lambo T M_126/chassis_57/chassis_emissive_ID_neons_LOD2_51/Object_90".get_active_material(0).emission_energy_multiplier = 16.0
			$"CarModel/Sketchfab_model/root/CarMesh/Lambo T M_126/glass_93/glass_glass_LOD2_92/Object_169".get_active_material(0).emission_energy_multiplier = 16.0
		if  Input.get_action_strength(inputs['motions']['down']['control_string']):
			$"CarModel/Sketchfab_model/root/CarMesh/Lambo T M_126/glass_93/glass_glass_LOD2_92/Object_169".get_active_material(0).emission_energy_multiplier = 0.3
			$"CarModel/Sketchfab_model/root/CarMesh/Lambo T M_126/chassis_57/chassis_emissive_ID_neons_LOD2_51/Object_90".get_active_material(0).emission_energy_multiplier = 0.3
			$CarModel/BackLight.visible = false
			$CarModel/BackLight2.visible = false
		
		steering = move_toward(steering, steer_target, STEER_SPEED * delta )

func traction(current_speed):
		apply_central_force(-transform.basis.y *( 1000 + (3 * current_speed/engine_force_value)))
	
# Update checkpoint count
func add_checkpoint(new_current_checkpoint: int, new_target_checkpoint: int, add_lap: bool = false) -> void:
	current_checkpoint = new_current_checkpoint
	target_checkpoint = new_target_checkpoint
	if add_lap:
		current_lap += 1
		if current_lap == max_lap_count +1:
			print('race over')
			win.emit(self)
	$Label3D.text = 'Current CHeck %s \n target: %s \n %s' % [str(current_checkpoint), str(target_checkpoint), str(current_lap)]

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
			camera.move_to_checkpoint(start_pos)
			tween.tween_property(self, "global_position", checkpoint.global_position + Vector3.UP * 2, 1.2)
			rotate_y(deg_to_rad(180))
			break
	await  tween.finished
	_handle_respawn()

func _handle_respawn() ->void:
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	mass = car_mass
	gravity_scale = 1
	print('done tweens')
	respawning = false
	show()
	camera.can_follow = true
