@tool
extends Path3D

@onready var checkpoint_holder: Node3D = $CheckPoints

@export_range(0, 100) var light_count = 0:
	set(value):
		light_count = value
		if Engine.is_editor_hint():
			spawn_light()
	get():
		return light_count

@export_range(0, 100) var check_points = 0:
	set(value):
		check_points = value
		if Engine.is_editor_hint():
			spawn_checkpoints()
	get():
		return check_points


func _ready() -> void:
	spawn_light()
	spawn_checkpoints()
	#spawn_vib_area()

func spawn_checkpoints() -> void:
	var offsets := []
	var points  = curve.get_baked_points() 
	var up_vectors = curve.get_baked_up_vectors()
	var tilts = curve.get_baked_tilts()
	
	# Clear child nodes
	for child in checkpoint_holder.get_children():
		child.free()
	# Set equal offset for all light nodes added
	for i in range(check_points):
		offsets.append(float(i)/float(check_points + 1))
	
	# For each point in offset, get each local upvector that corresponds to each point index
	for offset_index in range(offsets.size()):
		var index = clamp(int(points.size()) * offsets[offset_index], 0, points.size() -1)
		var point = points[index]
		var up_vector = up_vectors[index]
		var tilt = tilts[index]
		var future_point = points[index + 1]

		# Add light scene as a child of None3D type
		var _item_holder = Node3D.new()

		_item_holder.name = 'CheckPointsHolder'
		checkpoint_holder.add_child(_item_holder)
		_item_holder.translate(point)

		
		var item = preload("res://scenes/check_point/CheckPoint.tscn").instantiate()
		
		item.name = 'CheckPoint'
		item.checkpoint_index = offset_index

		var offset = curve.get_closest_offset(point)
		item.transform.basis = curve.sample_baked_with_rotation(offset, false, true).basis

		if offset_index == offsets.size() -1:
			item.checkpoint_target = 0
			item.is_start_finish = true
		else:
			item.checkpoint_target = offset_index + 1

		
		_item_holder.add_child(item)

func spawn_light() -> void:
	var offsets := []
	var points  = curve.get_baked_points() 
	var up_vectors = curve.get_baked_up_vectors()
	var tilts = curve.get_baked_tilts()
	
	# Clear child nodes
	for child in $TrackLights.get_children():
		child.free()
	
	# Set equal offset for all light nodes added
	for i in range(light_count):
		offsets.append(float(i)/float(light_count + 1))
	
	# For each point in offset, get each local upvector that corresponds to each point index
	for offset_index in range(offsets.size()):
		var index = clamp(int(points.size()) * offsets[offset_index], 0, points.size() -1)
		var point = points[index] 
		var up_vector = up_vectors[index]

		# Add light scene as a child of None3D type
		var _item_holder = Node3D.new()

		_item_holder.name = 'LightHolder'
		$TrackLights.add_child(_item_holder)
		_item_holder.translate(point)
		
		var item = preload("res://scenes/track_light/TrackLight.tscn").instantiate()
		item.name = 'Light'
		#item.scale = Vector3(0.001, .001, .001)

		_item_holder.translate(Vector3.UP * 0.45)
		_item_holder.add_child(item)

func spawn_vib_area() -> void:
	var offsets := []
	var points  = curve.get_baked_points() 
	var up_vectors = curve.get_baked_up_vectors()
	var width = $Inner.get_polygon()[0]
	var mid_point = (($Inner.get_polygon()[0] + $Inner.get_polygon()[1]) /2).x
	
	# Clear child nodes on build
	for child in $Inner/Vib.get_children():
		child.free()
	
	# Set equal offset for all light nodes added
	for i in range(300):
		offsets.append(float(i)/float(300 + 1))
	
	# For each point in offset, get each local upvector that corresponds to each point index
	for offset_index in range(offsets.size()):
		var index = clamp(int(points.size()) * offsets[offset_index], 0, points.size() -1)
		var point = points[index] * scale
		var up_vector = up_vectors[index]
		var closest_point = curve.get_closest_point(points[index])

		# Add area and collison instance
		var area = Area3D.new()
		area.collision_mask = 2
		area.body_entered.connect(_handle_player_overlap)

		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(2, 2.5, 2)
		
		collision_shape.shape = box_shape
		collision_shape.debug_color = Color.hex(0xff0425)
		area.add_child(collision_shape)
		area.transform.basis.y = up_vector
		
		$Inner/Vib.add_child(area)
		area.translate(point)
		
		area.look_at(points[index+10].direction_to(closest_point) * 400)
		area.translate(Vector3.RIGHT * mid_point * scale.x)
	
	spawn_left_vib(offsets, points, up_vectors, mid_point)

func spawn_left_vib(offsets, points, up_vectors, mid_point) -> void:
	# For each point in offset, get each local upvector that corresponds to each point index
	for offset_index in range(offsets.size()):
		var index = clamp(int(points.size()) * offsets[offset_index], 0, points.size() -1)
		var point = points[index] * scale
		var up_vector = up_vectors[index]
		var closest_point = curve.get_closest_point(points[index])

		# Add area and collison instance
		var area = Area3D.new()
		area.collision_mask = 2
		area.body_entered.connect(_handle_player_overlap)

		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(2, 2.5, 2)
		
		collision_shape.shape = box_shape
		collision_shape.debug_color = Color.hex(0xff0425)
		area.add_child(collision_shape)
		
		area.transform.basis.y = up_vector
		
		$Inner/Vib.add_child(area)
		area.translate(point)

		area.look_at(points[index+10].direction_to(closest_point) * 400)
		area.translate(Vector3.LEFT * mid_point * scale.x)

func _handle_player_overlap(body) -> void:
	if body is PlayerCar:
		#Input.start_joy_vibration(body.player_index, 0.5, 0.5, 0.2)
		pass
