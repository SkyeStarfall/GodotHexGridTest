extends Node3D

var _hex_data_reference: HexTileData = null


func init_tile(data_ref: HexTileData, position: Vector3):
	_hex_data_reference = data_ref
	
	self.position = position
	
	var m: StandardMaterial3D = $TileMesh.get_surface_override_material(0)
	var h: float = _hex_data_reference.get_height()
	
	if h > 2.4:
		m.albedo_color = Color(min(-2 + h, 1), 1, min(-2 + h, 1))
	elif h > 0.5:
		m.albedo_color = Color(1 - h, 1, 0)
	elif h < 0:
		m.albedo_color = Color(0, 1 + h, 1)
	else:
		m.albedo_color = Color(1 - h, 1, 0)
	
	var s = 5
	if h > 1./s:
		self.scale = Vector3(1, h * s, 1)
		self.position.y = h * (s/4.0) - 0.5
	else:
		self.position.y = -0.25
		self.scale = Vector3(1, 1, 1)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
