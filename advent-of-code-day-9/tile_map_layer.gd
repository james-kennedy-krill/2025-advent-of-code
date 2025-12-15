extends TileMapLayer
class_name MainTileMap

# Store custom colors per cell
var cell_colors: Dictionary = {}  # { Vector2i: Color }

func set_tile_modulate(coords: Vector2i, color: Color) -> void:
	if color == Color.WHITE:
		cell_colors.erase(coords)
	else:
		cell_colors[coords] = color

	# Tell Godot to re-run runtime updates where needed
	notify_runtime_tile_data_update()

# Called by Godot to know which cells need runtime updates
func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return coords in cell_colors

# Called by Godot for cells that returned true above
func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	var color:Color = cell_colors.get(coords, Color.WHITE)
	tile_data.modulate = color
