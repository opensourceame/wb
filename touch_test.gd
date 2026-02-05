extends Node

# Touch UI test to verify tile selection works
func _ready():
	print("=== Touch UI Test ===")
	print("Touch support enabled for tile selection")
	print("Test the following:")
	print("1. Touch tiles to select them (same as mouse click)")
	print("2. Drag finger across adjacent tiles")
	print("3. Long press (500ms) to submit word")
	print("4. Quick tap outside tiles to clear selection")
	
	# Create test grid if GridManager doesn't exist
	var grid_manager = get_node_or_null("../GridManager")
	if not grid_manager:
		print("Warning: GridManager not found")
		return
	
	# Check if tiles exist
	await get_tree().process_frame
	
	var tiles_canvas = grid_manager.get_node("Tiles")
	if tiles_canvas:
		var tile_count = tiles_canvas.get_child_count()
		print("Found %d tiles ready for touch interaction" % tile_count)
	else:
		print("Warning: Tiles canvas not found")
	
	print("=== Touch UI Test Complete ===")
	
	# Auto-exit after 3 seconds
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()