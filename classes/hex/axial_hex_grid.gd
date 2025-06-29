# Source for a lot of the methods: https://www.redblobgames.com/grids/hexagons

class_name AxialHexGrid extends Resource

enum MapShape {RECTANGLE, HEXAGONAL}

class HexGridDataBase extends RefCounted:
	var _width: int
	var _height: int
	var _grid: Array[Array]
	
	func _init(longest_width: int, longest_height: int):
		assert(false, "This is an abstract class. Please use an implementation class")
	
	func get_width() -> int:
		return _width
	
	func get_height() -> int:
		return _height
	
	func is_in_bounds(q: int, r: int):
		assert(false, "Please override `is_in_bounds()` in the derived script.")
	
	func get_q_range_at_r(r: int):
		assert(false, "Please override `get_q_range_at_r()` in the derived script.")

	func get_r_range_at_q(q: int):
		assert(false, "Please override `get_r_range_at_q()` in the derived script.")
	
	func get_at_axial(q: int, r: int):
		assert(false, "Please override `get_at_axial()` in the derived script.")
	
	func set_at_axial(q: int, r: int, value):
		assert(false, "Please override `set_at_axial()` in the derived script.")

class HexGridDataRectangle extends HexGridDataBase:
	func _init(longest_width: int, longest_height: int) -> void:
		_width = longest_width
		_height = longest_height
		_grid = []
		
		for row in range(0, longest_height):
			_grid.append([])
			for column in range(0, longest_width):
				_grid[row].append(null)
	
	# We store it as a rhombus, but abstract it away to act like a rectangle shape
	# this means every second row gets an additional 1 unit offset
	func is_in_bounds(q: int, r: int) -> bool:
		if q + floor(r/2) >= 0 and q + floor(r/2) < _width and r >= 0 and r < _height:
			return true
		return false
	
	func get_q_range_at_r(r: int) -> Array[int]:
		return [-floor(r/2), _width - floor(r/2)]

	func get_r_range_at_q(q: int) -> Array[int]:
		return [0, _height]
	
	func get_at_axial(q: int, r: int):
		assert(is_in_bounds(q, r), "Error: Trying to access (%d, %d) hex grid tile outside of bounds" % [q, r])
		
		return _grid[r][q + floor(r/2)]
	
	func set_at_axial(q: int, r: int, value) -> void:
		assert(is_in_bounds(q, r), "Error: Trying to set (%d, %d) hex grid tile outside of bounds" % [q, r])
		
		_grid[r][q + floor(r/2)] = value

class HexGridDataHexagonal extends HexGridDataBase:
	func _init(longest_width: int, longest_height: int) -> void:
		_width = longest_width
		_height = longest_height
		_grid = []
		
		for row in range(0, longest_height):
			_grid.append([])
			var r = get_q_range_at_r(row)
			for column in range(r[0], r[1]):
				_grid[row].append(null)
	
	# If there are performance issues, parts of these functions can be slightly optimized by caching
	func is_in_bounds(q: int, r: int) -> bool: # TEST
		var q_range = get_q_range_at_r(r)
		var r_range = get_r_range_at_q(q)
		if q >= q_range[0] and q < q_range[1] and r >= r_range[0] and r < r_range[1]:
			return true
		return false
	
	func get_q_range_at_r(r: int) -> Array[int]: # TEST
		return [max(0, floor(_height/2) - r), min(_width + floor(_height/2) - r, _width)]

	func get_r_range_at_q(q: int) -> Array[int]: # TEST
		return [max(0, floor(_width/2) - q), min(_height + floor(_width/2) - q, _height)]
	
	func get_at_axial(q: int, r: int): # TEST
		assert(is_in_bounds(q, r), "Error: Trying to access (%d, %d) hex grid tile outside of bounds" % [q, r])
		
		return _grid[r][q - max(0, floor(_height/2) - r)]
	
	func set_at_axial(q: int, r: int, value) -> void: # TEST
		assert(is_in_bounds(q, r), "Error: Trying to set (%d, %d) hex grid tile outside of bounds" % [q, r])
		
		_grid[r][q - max(0, floor(_height/2) - r)] = value

var hex_grid_data: HexGridDataBase

func _init(longest_width: int, longest_height: int, map_shape: MapShape):
	if map_shape == MapShape.RECTANGLE:
		hex_grid_data = HexGridDataRectangle.new(longest_width, longest_height)
	elif map_shape == MapShape.HEXAGONAL:
		hex_grid_data = HexGridDataHexagonal.new(longest_width, longest_height)

func get_longest_dimensions() -> Array[int]:
	return [hex_grid_data.get_width(), hex_grid_data.get_height()]

# Gives you min and max coordinate for the given coordinate in the used map shape
# Useful for finding the border tiles on the grid in axial coordinates
func get_q_range_at_r(r: int) -> Array[int]:
	return hex_grid_data.get_q_range_at_r(r)

func get_r_range_at_q(q: int) -> Array[int]:
	return hex_grid_data.get_r_range_at_q(q)

func is_in_bounds(q: int, r: int) -> bool: # TEST
	return hex_grid_data.is_in_bounds(q, r)

func get_at_axial(q: int, r: int):
	return hex_grid_data.get_at_axial(q, r)

func set_at_axial(q: int, r: int, value) -> void:
	hex_grid_data.set_at_axial(q, r, value)

# Method to generalize applying a method to every tile
# Saves boilerplate code
func for_each_tile(callable: Callable, data = null):
	var r: int = 0
	while(r < self.get_longest_dimensions()[1]):
		var q: int = self.get_q_range_at_r(r)[0]
		while(q < self.get_q_range_at_r(r)[1]):
			callable.call(q, r, data)
			
			q += 1
		r += 1

static func axial_round(frac_q: float, frac_r: float) -> Array[int]:
	var q = round(frac_q)
	var r = round(frac_r)
	var frac_s = -q-r
	var s = round(frac_s)

	var q_diff = abs(q - frac_q)
	var r_diff = abs(r - frac_r)
	var s_diff = abs(s - frac_s)

	if q_diff > r_diff and q_diff > s_diff:
		q = -r-s
	elif r_diff > s_diff:
		r = -q-s
	else:
		s = -q-r

	return [q, r]

static func pointy_hex_to_pixel(q: int, r: int) -> Array[float]:
	var x = sqrt(3.0) * q + sqrt(3.0)/2.0 * r
	var z = 3.0/2.0 * r
	return [x, z]

static func pixel_to_pointy_hex(x: float, y: float, size: float = 1.0) -> Array[int]:
	x = x / size
	y = y / size
	
	var q: float = (sqrt(3.0)/3.0 * x - 1.0/3.0 * y)
	var r: float = (2.0/3.0 * y)
	return axial_round(q, r)

static func pixel_to_flat_hex(x: float, y: float, size: float = 1.0) -> Array[int]:
	x = x / size
	y = y / size
	
	var q: float = (2.0/3.0 * x)
	var r: float = (-1.0/3.0 * x + sqrt(3.0)/3.0 * y)
	return axial_round(q, r)
