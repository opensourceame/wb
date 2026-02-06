extends Node

# Test script for tile dropping animation with row cycling
# Attach this to a test node in the scene to verify the animation works

func _ready():
	print("=== Tile Drop & Row Cycle Test Ready ===")
	print("Controls:")
	print("  'D' - Start CONTINUOUS tile drop cycles")
	print("  'C' - Start SINGLE tile drop cycle")
	print("  'S' - Stop all animations (disables continuous mode)")
	print("  'T' - Test single tile drop without row cycle")
	print("  'R' - Select a random tile to test protection")
	print("")
	print("The system will:")
	print("1. Drop all tiles down by one tile height (5 seconds)")
	print("2. Remove bottom row")
	print("3. Create new top row with random letters")
	print("4. Update all tile positions and neighbour connections")
	print("")
	print("CONTINUOUS MODE: After each cycle, waits 2 seconds then starts next cycle")
	print("SELECTION PROTECTION: Row cycles are SKIPPED if any tiles are selected")
	print("  → Test: Start continuous mode, then select tiles to see protection")
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
				print("\n🔄 Starting CONTINUOUS tile drop cycles...")
				grid_manager.start_tile_drop_animation(true)  # true = continuous mode
				print("→ Continuous mode activated")
				print("→ Each cycle: 5 seconds drop + 2 seconds delay")
				print("→ Press 'S' to stop continuous mode")
				
			KEY_C:
				print("\n🎬 Starting SINGLE tile drop cycle...")
				grid_manager.start_tile_drop_animation(false)  # false = single cycle
				print("→ Single cycle started")
				print("→ Bottom row will be removed after 5 seconds")
				print("→ New top row will be created")
				
			KEY_S:
				print("\n⏹ Stopping all animations...")
				grid_manager.stop_tile_drop_animation()
				print("→ All animations stopped")
				print("→ Continuous mode disabled")
				
			KEY_T:
				print("\n🧪 Testing single drop without row cycle...")
				# Test individual tile drop to verify animation works
				if grid_manager.columns.size() > 0 and grid_manager.columns[0].size() > 0:
					var test_tile = grid_manager.columns[0][0]
					test_tile.start_drop_animation()
					print("→ Started drop on tile: ", test_tile.letter, " at (0,0)")
				else:
					print("✗ No tiles found for testing")
					
			KEY_R:
				print("\n🎯 Selecting random tile to test protection...")
				# Find and select a random tile
				if grid_manager.columns.size() > 0:
					var random_q = randi() % grid_manager.columns.size()
					if grid_manager.columns[random_q].size() > 0:
						var random_r = randi() % grid_manager.columns[random_q].size()
						var test_tile = grid_manager.columns[random_q][random_r]
						if test_tile:
							grid_manager.select_tile(test_tile)
							print("→ Selected tile: ", test_tile.letter, " at (", random_q, ",", random_r, ")")
							print("→ Next cycle should be skipped!")
						else:
							print("✗ Selected tile was null")
					else:
						print("✗ No tiles in column ", random_q)
				else:
					print("✗ No columns available")