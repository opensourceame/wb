extends Node

# Test state management for HexTile touch UI
func _ready():
	print("=== Testing HexTile State Management ===")
	print("State enum: IDLE, SELECTED, IN_WORD, HOVER")
	
	# Create a test tile to verify states
	var test_tile = preload("res://scenes/HexTile.tscn").instantiate()
	add_child(test_tile)
	
	# Test state transitions
	test_tile.set_idle()
	print("Initial state: %s" % test_tile.current_state)
	
	test_tile.set_hover()
	print("After hover: %s" % test_tile.current_state)
	
	test_tile.set_selected(true)
	print("After selected: %s" % test_tile.current_state)
	
	test_tile.clear_hover()
	print("After clear hover: %s" % test_tile.current_state)
	
	print("=== State Management Test Complete ===")
	get_tree().quit()