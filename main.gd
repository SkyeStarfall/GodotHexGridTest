extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$FPS_Counter.text = "FPS: %.1f" % Engine.get_frames_per_second()

var time = 0
func _physics_process(delta: float) -> void:
	$HexWorld.render_at_pixel($Camera3D.position)
	
	# Debug info
	var a = AxialHexGrid.pixel_to_pointy_hex($Camera3D.position.x, $Camera3D.position.z, 1)
	var b = $HexWorld._hex_world_data.get_chunk_at_global_tile(a[0], a[1])
	$Debug_Label.text = "Position: " + str($Camera3D.position) + "\nGlobal Hex Tile: " + str(a) + "\nChunk: " + str(b.slice(0, 2)) + "\nTotal Chunks: " + str($HexWorld._hex_world_data._chunks.size()) + "\nTotal Hex Tiles: " + str(($HexWorld._hex_world_data._CHUNK_SIZE * $HexWorld._hex_world_data._CHUNK_SIZE * 3 + $HexWorld._hex_world_data._CHUNK_SIZE * 3 + 1) * $HexWorld._hex_world_data._chunks.size())


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("enable_debug"):
		get_viewport().debug_draw = (get_viewport().debug_draw + 1) % 6
