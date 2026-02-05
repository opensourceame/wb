extends Node

# Test script for tile dropping animation with row cycling
# Attach this to a test node in the scene to verify the animation works

func _ready():
	print("=== Tile Drop & Row Cycle Test Ready ===")
	print("Controls:")
	print("  'D' - Start tile drop animation + row cycle")
	print("  'S' - Stop tile drop animation")
	print("  'T' - Test single drop without row cycle")
	print("")
	print("The system will:")
	print("1. Drop all tiles down by one tile height (5 seconds)")
	print("2. Remove bottom row")
	print("3. Create new top row with random letters")
	print("4. Update all tile positions and neighbour connections")
	print("")
	
	# Get reference to grid manager
	var grid_manager = get_tree().current_scene.get_node("GridManager")
	if grid_manager:
		print("✓ Found GridManager")
	else:
		print("✗ ERROR: Could not find GridManager")

func _input(event):
	if event is InputEventKey and event.pressed:
		var grid_manager = get_tree().current_scene.get_node("GridManager")
		
		if not grid_manager:
			print("✗ ERROR: GridManager not found")
			return
		
		match event.keycode:
			KEY_D:
				print("\n🎬 Starting tile drop animation + row cycle...")
				grid_manager.start_tile_drop_animation()
				print("→ Animation started on all tiles")
				print("→ Bottom row will be removed after 5 seconds")
				print("→ New top row will be created")
				
			KEY_S:
				print("\n⏹ Stopping tile drop animation...")
				grid_manager.stop_tile_drop_animation()
				print("→ Animation stopped on all tiles")
				
			KEY_T:
				print("\n🧪 Testing single drop without row cycle...")
				# Test individual tile drop to verify animation works
				if grid_manager.columns.size() > 0 and grid_manager.columns[0].size() > 0:
					var test_tile = grid_manager.columns[0][0]
					test_tile.start_drop_animation()
					print("→ Started drop on tile: ", test_tile.letter, " at (0,0)")
				else:
					print("✗ No tiles found for testing")