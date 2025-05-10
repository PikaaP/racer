@tool
extends MeshInstance3D

@export var path: Path3D

@export var road_height: float = 0.5 :
	get:
		return road_height
	set(value):
		road_height = value

@export var road_width: float = 1.0:
	get:
		return road_width
	set(value):
		road_width = value

@export_tool_button("Bake", "Callable") var generate_road_action = generate_road

var baked_points: PackedVector3Array
var baked_up_vectors: PackedVector3Array

func generate_road():
	baked_points = path.curve.get_baked_points()
	baked_up_vectors = path.curve.get_baked_up_vectors()
	
	var all_vertices: PackedVector3Array = []
	# Get baked points in track path

	for i in baked_points.size():
		all_vertices.append_array(build_mesh_strip(i))

	# Initialize the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = all_vertices

	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Update road mesh
	mesh = arr_mesh
	var surface_material = StandardMaterial3D.new()
	surface_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	material_override = surface_material


func build_mesh_strip(index: int) -> PackedVector3Array:
	# Get center point properties
	var center_point = baked_points[index]
	var up_vector = baked_up_vectors[index]
	var next_point

	if index + 1 >= baked_points.size():
		next_point = baked_points[index-1]
	else:
		next_point = baked_points[index + 1]
		
	
	# Create PackedVector3 to hold all of the rectangles vertices
	var vertices = PackedVector3Array()
	# Get the road construction properties
	# Road height
	var baked_height: float = get('road_height')
	var baked
	# Road width from the center of the road
	var baked_width_half: float = get('road_width')/2
	# Width of each constructed mesh, smoother mesh with more smaller width
	var baked_segment_width_half = path.curve.bake_interval

	# Back 
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y + baked_height, center_point.z + baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y + 0, center_point.z + baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y + 0, center_point.z + baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + baked_width_half, baked_height, baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, baked_height, baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + baked_width_half, 0, baked_segment_width_half))
#
	## Front 
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  baked_height,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  0,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + 0,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + baked_height,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  baked_height,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + 0,  center_point.z + -baked_segment_width_half))

	# Side 1
	#vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + baked_height,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + baked_height, center_point.z +  baked_segment_width_half))
	#vertices.push_back(Vector3(next_point.x + baked_width_half,  center_point.y + 0, center_point.z +  baked_segment_width_half))
	#
	#vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + baked_height,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + 0, center_point.z +  baked_segment_width_half))
	#vertices.push_back(Vector3(next_point.x + baked_width_half,  center_point.y + 0,  center_point.z + -baked_segment_width_half))

	## Side 2
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  baked_height,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  baked_height, center_point.z +  baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  0, center_point.z +  baked_segment_width_half))
	#
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  baked_height,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +0, center_point.z + baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +0, center_point.z + -baked_segment_width_half))
	#
	## Top 
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  baked_height, center_point.z +  baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  baked_height,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + baked_height, center_point.z +  baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + baked_height, center_point.z +  baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  baked_height,  center_point.z + -baked_segment_width_half))
	#vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + baked_height,  center_point.z + -baked_segment_width_half))
#
	## Bottom
	var new_basis = Basis()
	var forward_dir = center_point.direction_to(next_point)
	
	new_basis.z = forward_dir
	#new_basis.y = up_vector
	new_basis = new_basis.looking_at(next_point, up_vector, false)

	print(new_basis)
	
	
	vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  0, center_point.z +  baked_segment_width_half))
	vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  0,  center_point.z + -baked_segment_width_half))
	vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + 0, center_point.z +  baked_segment_width_half))
	
	vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + 0, center_point.z +  baked_segment_width_half))
	vertices.push_back(Vector3(center_point.x + -baked_width_half, center_point.y +  0,  center_point.z + -baked_segment_width_half))
	vertices.push_back(Vector3(center_point.x + baked_width_half,  center_point.y + 0,  center_point.z + -baked_segment_width_half))

	return vertices
