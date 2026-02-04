# Test WordChecker functionality
# Run this in Godot's script editor or attach to a test scene

extends Node

func _ready():
	print("=== Testing WordChecker ===")
	
	var checker = WordChecker.new()
	
	# Test manually
	var test_words = ["THE", "AND", "HELLO", "XYZ"]
	
	for word in test_words:
		var is_valid = checker.is_valid_word(word)
		print("Word '%s': %s" % [word, is_valid])
	
	print("=== Test Complete ===")