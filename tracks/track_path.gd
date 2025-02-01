@tool
extends Path3D

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

func spawn_checkpoints() -> void:
	var offsets := []
	var points  = curve.get_baked_points() 
	var up_vectors = curve.get_baked_up_vectors()
	# Clear child nodes
	for child in $CheckPoints.get_children():
		child.free()
	# Set equal offset for all light nodes added
	for i in range(check_points):
		offsets.append(float(i)/float(check_points + 1))
	
	# For each point in offset, get each local upvector that corresponds to each point index
	for offset_index in range(offsets.size()):
		var index = clamp(int(points.size()) * offsets[offset_index], 0, points.size() -1)
		var point = points[index]
		var up_vector = up_vectors[index]
		var closest_point = curve.get_closest_point(points[index])

		# Add light scene as a child of None3D type
		var _item_holder = Node3D.new()

		_item_holder.name = 'CheckPointsHolder'
		$CheckPoints.add_child(_item_holder)
		_item_holder.translate(point)
		
		var item = preload("res://scenes/check_point/CheckPoint.tscn").instantiate()
		item.name = 'CheckPoint'
		item.checkpoint_index = offset_index

		if offset_index == offsets.size() -1:
			item.checkpoint_target = 0
			item.is_start_finish = true
		else:
			item.checkpoint_target = offset_index + 1
		
		item.scale = Vector3(0.015, 0.015, 0.015)
		_item_holder.add_child(item)
		
		item.look_at(points[index+10].direction_to(closest_point) * 400)

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
		item.scale = Vector3(0.001, .001, .001)

		_item_holder.translate(Vector3.UP * 0.45) 
		_item_holder.add_child(item)
