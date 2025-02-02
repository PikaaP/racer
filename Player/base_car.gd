class_name PlayerCar extends VehicleBody3D

signal win(player: PlayerCar)

@onready var ground_ray: RayCast3D = $GroundRay
@onready var respawn_timer: Timer = $RespawnTimer

@export var checkpoint_array = []
@export var current_checkpoint: int = 0
@export var target_checkpoint: int = 0
@export var current_lap: int = 0
@export var max_lap_count: int

@export var inputs = {}
@export var player_index: int 

@export var car_resource: CarStats
@export var STEER_SPEED: float = 1.1
@export var STEER_LIMIT = 0.4
@export var engine_force_value = 200
@export var max_drift_recovery_time: float = 2.0

var steer_target: float
var speed_input: float
var drift_recovery_time = 0
var speed = 0
var respawning = false

func _ready() -> void:
	print('inputs for me: ' , name, ' ', inputs)
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
		engine_force = speed_input
		
		drift_recovery_time = clamp(drift_recovery_time + delta/10 *abs(steer_target), 0, max_drift_recovery_time)
		if Input.is_action_pressed(inputs['buttons']["drift"]['control_string']):
			pass
			#drift_recovery_time = 0
			#$wheel_0.wheel_friction_slip=0.7
			#$wheel_1.wheel_friction_slip=0.7
			#$wheel_2.wheel_friction_slip=0.3
			#$wheel_3.wheel_friction_slip=0.3
			#apply_central_force(((transform.basis.x * -steer_target) * -engine_force_value * speed_input/engine_force_value * 1.1))
			#apply_central_force(((transform.basis.z * -speed_input/engine_force_value) * -engine_force_value * (1 + speed_input/engine_force_value)))
		#else:
			#$wheel_0.wheel_friction_slip= min($wheel_0.wheel_friction_slip+ drift_recovery_time , 2.2)
			#$wheel_1.wheel_friction_slip= min($wheel_0.wheel_friction_slip+ drift_recovery_time , 2.2)
			#$wheel_2.wheel_friction_slip= min($wheel_0.wheel_friction_slip+ drift_recovery_time , 2.0)
			#$wheel_3.wheel_friction_slip= min($wheel_0.wheel_friction_slip+ drift_recovery_time , 2.0)

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

func traction(speed):
		apply_central_force(-transform.basis.y * 5)

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
	respawning = true
	respawn_timer.start()
	gravity_scale = 0
	
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
	var checkpoints  = get_tree().get_nodes_in_group('checkpoint')
	for checkpoint: CheckPoint in checkpoints:
		if checkpoint.checkpoint_index == current_checkpoint:
			transform.basis =  checkpoint.transform.basis
			var tween = get_tree().create_tween()
			var start_pos = global_position
			tween.tween_property(self, "global_position", checkpoint.global_position + Vector3.UP * 3.5, 1)
			apply_central_force(Vector3.ZERO)
			rotate_y(deg_to_rad(180))
			break

func _handle_respawn() ->void:
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	respawning = false
	gravity_scale = 1
