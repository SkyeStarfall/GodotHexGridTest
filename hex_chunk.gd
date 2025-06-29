extends Node3D

var _hex_chunk_data_reference: AxialHexGrid = null

var thread_task_id = -1

func init_chunk(data_ref: AxialHexGrid, q_offset: int, r_offset: int, dependent_generate_thread: int) -> void:
	_hex_chunk_data_reference = data_ref
	
	thread_task_id = WorkerThreadPool.add_task(_generate_chunk_mesh_thread.bind(q_offset, r_offset, dependent_generate_thread), false, "_threaded_generate_chunk_mesh")
	#$MeshInstance3D.mesh = _generate_chunk_mesh(q_offset, r_offset)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

# UNUSED
func _generate_circle(segments: int) -> ArrayMesh:
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var prev_point = 1
	
	verts.append(Vector3(0, 0, 0))
	normals.append(Vector3(0, 1, 0))
	
	for i in range(1, segments + 2):
		var vert: Vector3
		
		var u = (i - 1) / float(segments)
		
		var x = sin(2 * PI * u)
		var z = cos(2 * PI * u)
		
		vert = Vector3(x, 0, z)
		
		verts.append(vert)
		normals.append(vert.normalized())
		
		if i > 1:
			indices.append(prev_point)
			indices.append(0)
			indices.append(i)
		
		prev_point = i
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	return array_mesh

# UNUSED
func _generate_sphere() -> ArrayMesh:
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var rings = 50
	var radial_segments = 50
	var radius = 1
	
	var thisrow = 0
	var prevrow = 0
	var point = 0
	
	# Loop over rings.
	for i in range(rings + 1):
		var v = float(i) / rings
		var w = sin(PI * v)
		var y = cos(PI * v)
		
		# Loop over segments in ring.
		for j in range(radial_segments + 1):
			var u = float(j) / radial_segments
			var x = sin(u * PI * 2.0)
			var z = cos(u * PI * 2.0)
			var vert = Vector3(x * radius * w, y * radius, z * radius * w)
			verts.append(vert)
			normals.append(vert.normalized())
			point += 1
			
			# Create triangles in ring using indices.
			if i > 0 and j > 0:
				indices.append(prevrow + j - 1)
				indices.append(prevrow + j)
				indices.append(thisrow + j - 1)
				
				indices.append(prevrow + j)
				indices.append(thisrow + j)
				indices.append(thisrow + j - 1)
		
		prevrow = thisrow
		thisrow = point
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	return array_mesh

# UNUSED
func _generate_hex_tile(q: int, r: int) -> ArrayMesh:
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var pos_offset = AxialHexGrid.pointy_hex_to_pixel(q, r)
	
	var height = 1
	
	var prev_point = 0
	var point = 0
	
	# Draw the sides
	for i in range(0, 7):
		var norm_u = i / 6.0
		var norm = Vector3(sin(2 * PI * norm_u + PI/4) + pos_offset[0], 0, cos(2 * PI * norm_u + PI/4) + pos_offset[1]).normalized()
		for j in range(0, 2):
			var u = (i + j) / 6.0
			var x = sin(2 * PI * u) + pos_offset[0]
			var z = cos(2 * PI * u) + pos_offset[1]
			for k in range(0, 2):
				var y = k * height
				
				var vert = Vector3(x, y, z)
				
				verts.append(vert)
				normals.append(norm)
				
				if j > 0:
					# To ensure correct orientation of the faces (clockwise winding order)
					if k == 0:
						indices.append(prev_point - 1)
						indices.append(prev_point)
						indices.append(point)
					else:
						indices.append(prev_point)
						indices.append(prev_point - 1)
						indices.append(point)
				
				prev_point = point
				point += 1
	
	# Add a center vertex to create the top triangles against
	var top_center_vertex_index: int = verts.size()
	verts.append(Vector3(0 + pos_offset[0], height, 0 + pos_offset[1]))
	normals.append(Vector3(0, 1, 0))
	
	for i in range(1, 8):
		var u = i / 6.0
		var x = sin(2 * PI * u) + pos_offset[0]
		var z = cos(2 * PI * u) + pos_offset[1]
		
		var vert = Vector3(x, height, z)
		verts.append(vert)
		normals.append(Vector3(0, 1, 0))
		
		if i > 1:
			indices.append(top_center_vertex_index + i - 1)
			indices.append(top_center_vertex_index)
			indices.append(top_center_vertex_index + i)
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	return array_mesh

func _append_hex_tile(surface_array: Array, q: int, r: int, index: int, tile: HexTileData) -> void:
	var pos_offset = AxialHexGrid.pointy_hex_to_pixel(q, r)
	# 31 is a "magic" number here, which correlates to the amount of vertices we generate per hex tile
	var index_offset = index * 36
	
	var height = tile.get_height()
	var color: Color = tile.get_color()
	
	height = max(0, height)
	
	var prev_point = 0
	var point = 0
	
	# Draw the sides
	for i in range(0, 7):
		var norm_u = i / 6.0
		var norm = Vector3(sin(2 * PI * norm_u + PI/4), 0, cos(2 * PI * norm_u + PI/4)).normalized()
		for j in range(0, 2):
			var u = (i + j) / 6.0
			var x = sin(2 * PI * u) + pos_offset[0]
			var z = cos(2 * PI * u) + pos_offset[1]
			for k in range(0, 2):
				var y = k * height
				
				var vert = Vector3(x, y, z)
				
				surface_array[Mesh.ARRAY_VERTEX].append(vert)
				surface_array[Mesh.ARRAY_NORMAL].append(norm)
				surface_array[Mesh.ARRAY_COLOR].append(color)
				
				if j > 0:
					# To ensure correct orientation of the faces (clockwise winding order)
					if k == 0:
						surface_array[Mesh.ARRAY_INDEX].append(index_offset + prev_point - 1)
						surface_array[Mesh.ARRAY_INDEX].append(index_offset + prev_point)
						surface_array[Mesh.ARRAY_INDEX].append(index_offset + point)
					else:
						surface_array[Mesh.ARRAY_INDEX].append(index_offset + prev_point)
						surface_array[Mesh.ARRAY_INDEX].append(index_offset + prev_point - 1)
						surface_array[Mesh.ARRAY_INDEX].append(index_offset + point)
				
				prev_point = point
				point += 1
	
	# Add a center vertex to create the top triangles against
	var top_center_vertex_index: int = surface_array[Mesh.ARRAY_VERTEX].size()
	surface_array[Mesh.ARRAY_VERTEX].append(Vector3(0 + pos_offset[0], height, 0 + pos_offset[1]))
	surface_array[Mesh.ARRAY_NORMAL].append(Vector3(0, 1, 0))
	surface_array[Mesh.ARRAY_COLOR].append(color)
	
	for i in range(1, 8):
		var u = i / 6.0
		var x = sin(2 * PI * u) + pos_offset[0]
		var z = cos(2 * PI * u) + pos_offset[1]
		
		var vert = Vector3(x, height, z)
		surface_array[Mesh.ARRAY_VERTEX].append(vert)
		surface_array[Mesh.ARRAY_NORMAL].append(Vector3(0, 1, 0))
		surface_array[Mesh.ARRAY_COLOR].append(color)
		
		if i > 1:
			surface_array[Mesh.ARRAY_INDEX].append(top_center_vertex_index + i - 1)
			surface_array[Mesh.ARRAY_INDEX].append(top_center_vertex_index)
			surface_array[Mesh.ARRAY_INDEX].append(top_center_vertex_index + i)

# UNUSED
func _generate_chunk_mesh(q_offset: int, r_offset: int) -> ArrayMesh:
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_COLOR] = colors
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	var i = 0
	for r in range(0, _hex_chunk_data_reference.get_longest_dimensions()[1]):
		for q in range(_hex_chunk_data_reference.get_q_range_at_r(r)[0], _hex_chunk_data_reference.get_q_range_at_r(r)[1]):
			var h = _hex_chunk_data_reference.get_at_axial(q, r).get_height()
			
			_append_hex_tile(surface_array, q + q_offset, r + r_offset, i, h)
			
			i += 1
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	return array_mesh

func _generate_chunk_mesh_thread(q_offset: int, r_offset: int, dependent_generate_thread: int):
	if dependent_generate_thread != -1:
		while not WorkerThreadPool.is_task_completed(dependent_generate_thread):
			OS.delay_msec(10) # Waits until the dependent task is complete. Imperfect solution TODO: Find a better solution
		WorkerThreadPool.wait_for_task_completion(dependent_generate_thread) # Cleanup the dependent task
	
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_COLOR] = colors
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	var i = 0
	for r in range(0, _hex_chunk_data_reference.get_longest_dimensions()[1]):
		for q in range(_hex_chunk_data_reference.get_q_range_at_r(r)[0], _hex_chunk_data_reference.get_q_range_at_r(r)[1]):
			var tile = _hex_chunk_data_reference.get_at_axial(q, r)
			
			_append_hex_tile(surface_array, q + q_offset, r + r_offset, i, tile)
			
			i += 1
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	call_deferred("_finish_mesh", array_mesh)

func _finish_mesh(finished_mesh: ArrayMesh):
	$MeshInstance3D.mesh = finished_mesh
	WorkerThreadPool.wait_for_task_completion(thread_task_id) # Cleanup
