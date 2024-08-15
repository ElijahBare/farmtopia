extends TileMap

var last_hovered_tile = Vector2i(-1, -1)
var highlight_node: Node2D

func _ready():
	highlight_node = Node2D.new()
	add_child(highlight_node)
	
	# Create a polygon to represent the tile highlight
	var polygon = Polygon2D.new()
	polygon.color = Color(1, 1, 1, 0.3)  # Semi-transparent white
	highlight_node.add_child(polygon)
	
	# Set up the polygon shape based on tile size
	var size = tile_set.tile_size
	polygon.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(size.x, 0),
		Vector2(size.x, size.y),
		Vector2(0, size.y)
	])
	
	highlight_node.hide()

func _process(delta):
	var mouse_pos = get_local_mouse_position()
	var tile_pos = local_to_map(mouse_pos - Vector2(10, 10)) #mouse center vs pointer is 10 pixels
	
	if tile_pos != last_hovered_tile:
		if get_cell_source_id(0, tile_pos) != -1:  # Check if there's a tile
			highlight_node.show()
			highlight_node.position = map_to_local(tile_pos)
		else:
			highlight_node.hide()
		
		last_hovered_tile = tile_pos

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_local_mouse_position()
		var tile_pos = local_to_map(mouse_pos - Vector2(10, 10))
		print("Clicked on tile: ", tile_pos)
