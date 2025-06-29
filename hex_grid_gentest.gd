extends Node3D

var _hex_tile: PackedScene = preload("res://hex_tile.tscn")

var _hex_grid

var _noise: FastNoiseLite = FastNoiseLite.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_hex_grid = AxialHexGrid.new(200, 200, AxialHexGrid.MapShape.RECTANGLE)
	
	var r: int = 0
	while(r < _hex_grid.get_longest_dimensions()[1]):
		var q: int = _hex_grid.get_q_range_at_r(r)[0]
		while(q < _hex_grid.get_q_range_at_r(r)[1]):
			var new_tile: Node3D = _hex_tile.instantiate()
			
			# The mesh itself is normalized to a size of 1m
			var size = 1
			new_tile.scale *= size
			
			# "Magic" numbers to convert axial hex coordinates into cartesian positions
			var pos = AxialHexGrid.pointy_hex_to_pixel(q, r)
			new_tile.position.x = pos[0] * size
			new_tile.position.y = 0
			new_tile.position.z = pos[1] * size
			
			self.add_child(new_tile)
			
			_hex_grid.hex_grid_data.set_at_axial(q, r, new_tile)
			
			q += 1
		r += 1
	
	_noise.frequency = 0.001
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.fractal_type = FastNoiseLite.FRACTAL_NONE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


var time_count = 0
var time_count2 = 0

func _physics_process(delta: float) -> void:
	time_count += delta * 0
	time_count2 += delta
	
	if time_count2 < 5:
		return
	else:
		time_count2 -= 100000
	
	var r: int = 0
	while(r < _hex_grid.get_longest_dimensions()[1]):
		var q: int = _hex_grid.get_q_range_at_r(r)[0]
		while(q < _hex_grid.get_q_range_at_r(r)[1]):
			var tile: Node3D = _hex_grid.hex_grid_data.get_at_axial(q, r)
			
			var v = _noise.get_noise_2d((time_count + tile.position.x * 1) * 100, (time_count + tile.position.z * 1) * 100) + _noise.get_noise_2d((time_count + tile.position.x * 1) * 1, (time_count + tile.position.z * 1) * 1) * 10
			#tile.visible = _noise.get_noise_2d((time_count + tile.position.x * 1) * 100, (time_count + tile.position.z * 1) * 100) + _noise.get_noise_2d((time_count + tile.position.x * 1) * 1, (time_count + tile.position.z * 1) * 1) * 10 > 0
			var m: StandardMaterial3D = tile.get_child(0).get_surface_override_material(0)
			
			#if v > 1:
			#	v = 1
			
			if v > 2.4:
				m.albedo_color = Color(min(-2 + v, 1), 1, min(-2 + v, 1))
			elif v > 0.5:
				m.albedo_color = Color(1 - v, 1, 0)
			elif v < 0:
				m.albedo_color = Color(0, 1 + v, 1)
			else:
				m.albedo_color = Color(1 - v, 1, 0)
			
			var s = 5
			if v > 1./s:
				tile.scale = Vector3(1, v * s, 1)
				tile.position.y = v * (s/4.0) - 0.5
			else:
				tile.position.y = -0.25
				tile.scale  = Vector3(1, 1, 1)
			
			q += 1
		r += 1
