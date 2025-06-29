extends Node3D

const _RENDER_DISTANCE: int = 32

class HexWorldData extends RefCounted:
	const _CHUNK_SIZE: int = 25 # Diameter. Radius is floor(_CHUNK_SIZE/2)
	const _TILE_SIZE: float = 1.0 # The mesh itself is normalized to a size of 1m
	
	#var _hex_tile: PackedScene = preload("res://hex_tile.tscn")
	var _chunk_scene: PackedScene = preload("res://hex_chunk.tscn")
	
	var _world_gen: WorldGen = null
	
	var _chunks: Dictionary
	
	func _init() -> void:
		_world_gen = WorldGen.new()
	
	func is_chunk_generated(q: int, r: int) -> bool:
		return [q, r] in _chunks
	
	func get_chunk(q: int, r: int) -> AxialHexGrid:
		assert(is_chunk_generated(q, r), "Error: Trying to access (%d, %d) chunk which has not been generated" % [q, r])
		return _chunks[[q, r]]
	
	# https://observablehq.com/@sanderevers/hexagon-tiling-of-an-hexagonal-grid
	# Adjusted for the scuffed coordinate system I use
	func get_chunk_at_global_tile(global_q: int, global_r: int) -> Array[int]:
		global_q = global_q - _CHUNK_SIZE / 2
		global_r = global_r - _CHUNK_SIZE / 2
		var global_s: int = -global_q - global_r
		
		var r: int = floor(_CHUNK_SIZE / 2)
		var shift: int = 3 * r + 2
		var area: int = 3 * r * r + 3 * r + 1
		
		var qh: int = floor((global_s - 1 + shift * (global_q)) / float(area))
		var rh: int = floor((global_q - 1 + shift * (global_r)) / float(area))
		var sh: int = floor((global_r - 1 + shift * (global_s)) / float(area))
		
		var chunk_q: int = floor((1 + qh - sh) / 3.0)
		var chunk_r: int = floor((1 + rh - qh) / 3.0)
		var chunk_s: int = floor((1 + sh - rh) / 3.0)
		
		return [chunk_q, chunk_r, chunk_s, qh, rh, sh]
	
	func get_global_tile_from_chunk_local(local_q: int, local_r: int, chunk_q: int, chunk_r: int) -> Array[int]:
		var q_offset: int = chunk_q * (floor(HexWorldData._CHUNK_SIZE/2) + 1) - chunk_r * (floor(HexWorldData._CHUNK_SIZE/2))
		var r_offset: int = chunk_r * HexWorldData._CHUNK_SIZE + (chunk_q * floor(HexWorldData._CHUNK_SIZE/2))
		return [local_q + q_offset, local_r + r_offset]
	
	func _generate_chunk_threaded(chunk_q: int, chunk_r: int, hex_chunk: AxialHexGrid):
		for r in range(0, hex_chunk.get_longest_dimensions()[1]):
			for q in range(hex_chunk.get_q_range_at_r(r)[0], hex_chunk.get_q_range_at_r(r)[1]):
				var global_tile = self.get_global_tile_from_chunk_local(q, r, chunk_q, chunk_r)
				var global_tile_pos = AxialHexGrid.pointy_hex_to_pixel(global_tile[0], global_tile[1])
				var height = self._world_gen.sample_point(global_tile_pos[0], global_tile_pos[1])
				var color = self._world_gen.color_hex(height)
				
				var new_tile_data: HexTileData = HexTileData.new(height, color)
				
				hex_chunk.hex_grid_data.set_at_axial(q, r, new_tile_data)
	
	func generate_chunk_thread(chunk_q: int, chunk_r: int) -> int:
		assert(not is_chunk_generated(chunk_q, chunk_r), "Error: (%d, %d) Chunk already generated" % [chunk_q, chunk_r])
		
		var hex_chunk: AxialHexGrid = AxialHexGrid.new(_CHUNK_SIZE, _CHUNK_SIZE, AxialHexGrid.MapShape.HEXAGONAL)
		
		var task_id = WorkerThreadPool.add_task(_generate_chunk_threaded.bind(chunk_q, chunk_r, hex_chunk), false, "_generate_chunk_threaded for chunk (%d, %d)" % [chunk_q, chunk_r])
		_chunks[[chunk_q, chunk_r]] = hex_chunk
		
		return task_id
	
	func render_chunk(chunk_q: int, chunk_r: int, dependent_generate_thread: int) -> Node3D:
		var hex_chunk: AxialHexGrid = get_chunk(chunk_q, chunk_r)
		
		var chunk: Node3D = _chunk_scene.instantiate()
		
		var offset: Array[int] = get_global_tile_from_chunk_local(0, 0, chunk_q, chunk_r)
		
		chunk.init_chunk(hex_chunk, offset[0], offset[1], dependent_generate_thread)
		
		return chunk
	
	func regenerate() -> void:
		self._chunks.clear()


var _hex_world_data: HexWorldData = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_hex_world_data = HexWorldData.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("reload_map"):
		self.regenerate()

# "dependent_generate_thread = -1" means that there is no dependent generate thread
# in other words, it's guaranteed that the chunk data has already been generated and exists
func render_chunk(chunk_q: int, chunk_r: int, dependent_generate_thread: int = -1) -> void:
	var chunk_node = _hex_world_data.render_chunk(chunk_q, chunk_r, dependent_generate_thread)
	self.add_child(chunk_node)

func render_at(chunk_q: int, chunk_r: int) -> void:
	for r in range(-_RENDER_DISTANCE, _RENDER_DISTANCE + 1):
		# Renders a hexagon of radius RENDER_DISTANCE chunks around you
		var q_range = [max(-_RENDER_DISTANCE, -_RENDER_DISTANCE - r), min(_RENDER_DISTANCE - r + 1, _RENDER_DISTANCE + 1)]
		var q = q_range[0]
		while(q < q_range[1]):
			if not _hex_world_data.is_chunk_generated(q + chunk_q, r + chunk_r):
				var generate_task_id = _hex_world_data.generate_chunk_thread(q + chunk_q, r + chunk_r)
				self.render_chunk(q + chunk_q, r + chunk_r, generate_task_id)
			
			q += 1

func render_at_pixel(pos: Vector3) -> void:
	var global_hex = AxialHexGrid.pixel_to_pointy_hex(pos.x, pos.z, 1)
	var chunk = _hex_world_data.get_chunk_at_global_tile(global_hex[0], global_hex[1])
	self.render_at(chunk[0], chunk[1])

# TODO Doesn't currently work properly due to threading issues
func regenerate() -> void:
	for i in self.get_children():
		i.queue_free()
	_hex_world_data.regenerate()
