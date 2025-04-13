@tool
extends MeshInstance3D

@export_tool_button("Bake", "Callable") var generate_road_action = square


func square():
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	# PackedVector**Arrays for mesh construction.
	var verts = PackedVector3Array()

	#######################################
	#verts.push_back(Vector3(0,1,0))
	#verts.push_back(Vector3(0,0,0))
	#verts.push_back(Vector3(1,0,0))
	#
	#verts.push_back(Vector3(1,1,0))
	#verts.push_back(Vector3(0,1,0))
	#verts.push_back(Vector3(1,0,0))
	#
	verts.push_back(Vector3(0,1,0).rotated(Vector3.RIGHT, deg_to_rad(90)))
	verts.push_back(Vector3(0,0,0).rotated(Vector3.RIGHT, deg_to_rad(90)))
	verts.push_back(Vector3(1,0,0).rotated(Vector3.RIGHT, deg_to_rad(90)))
	
	verts.push_back(Vector3(1,1,0).rotated(Vector3.RIGHT, deg_to_rad(90)))
	verts.push_back(Vector3(0,1,0).rotated(Vector3.RIGHT, deg_to_rad(90)))
	verts.push_back(Vector3(1,0,0).rotated(Vector3.RIGHT, deg_to_rad(90)))
	
	
	#######################################

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts

	# Create mesh surface from mesh array.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
