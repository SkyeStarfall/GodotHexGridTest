class_name HexTileData extends RefCounted

var height: float
var color: Color

func _init(h: float, c: Color) -> void:
	self.height = h
	self.color = c

func get_height() -> float:
	return self.height

func get_color() -> Color:
	return self.color
