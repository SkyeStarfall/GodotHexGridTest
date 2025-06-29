class_name WorldGen extends RefCounted


var _large_scale_heightness_noise: FastNoiseLite = null
var _mountain_range_noise: FastNoiseLite = null

func _init() -> void:
	_large_scale_heightness_noise = FastNoiseLite.new()
	
	_large_scale_heightness_noise.frequency = 0.0003
	_large_scale_heightness_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_large_scale_heightness_noise.fractal_type = FastNoiseLite.FRACTAL_NONE

func sample_point(x: float, y: float) -> float:
	var large_scale_heightness: float = _large_scale_heightness_noise.get_noise_2d(x, y)
	
	return large_scale_heightness

func color_hex(height: float) -> Color:
	var color: Color
	if height > 2.4:
		color = Color(min(-2 + height, 1), 1, min(-2 + height, 1))
	elif height > 0.5:
		color = Color(1 - height, 1, 0)
	elif height < 0:
		color = Color(0, 1 + height, 1)
	else:
		color = Color(1 - height, 1, 0)
	return color









# Old below

#var _noise: FastNoiseLite = null
#
#func _init() -> void:
	#_noise = FastNoiseLite.new()
	#
	#_noise.frequency = 0.001
	#_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	#_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
#
#func sample_point(x: float, y: float) -> float:
	#var large_landscape: float = _noise.get_noise_2d(x, y) * 10
	#var detailed_landscape: float = _noise.get_noise_2d(x * 100, y * 100)
	#var value = large_landscape + detailed_landscape
	#
	#return value
#
#func color_hex(height: float) -> Color:
	#var color: Color
	#if height > 2.4:
		#color = Color(min(-2 + height, 1), 1, min(-2 + height, 1))
	#elif height > 0.5:
		#color = Color(1 - height, 1, 0)
	#elif height < 0:
		#color = Color(0, 1 + height, 1)
	#else:
		#color = Color(1 - height, 1, 0)
	#return color
