extends Node

# Direct WordChecker test without async loading
func _ready():
	print("=== WordChecker Direct Test ===")
	
	# Create WordChecker instance
	var word_checker = WordChecker.new()
	add_child(word_checker)
	
	# Manually trigger loading without thread
	_load_test_dictionary(word_checker)
	
	print("Test dictionary loaded!")
	
	# Test basic functionality
	var word_tests = [
		["THE", true],
		["AND", true], 
		["FOR", true],
		["XYZ", false],
		["QQQ", false]
	]
	
	print("\nWord validation tests:")
	for test in word_tests:
		var word = test[0]
		var expected = test[1]
		var result = word_checker.is_valid_word(word)
		var status = "PASS" if result == expected else "FAIL"
		print("  '%s' -> %s (%s)" % [word, result, status])
	
	# Test prefix validation
	var prefix_tests = [
		["TH", true],
		["AB", true],
		["XYZ", false]
	]
	
	print("\nPrefix validation tests:")
	for test in prefix_tests:
		var prefix = test[0]
		var expected = test[1]
		var result = word_checker.is_valid_prefix(prefix)
		var status = "PASS" if result == expected else "FAIL"
		print("  '%s' -> %s (%s)" % [prefix, result, status])
	
	# Test scoring
	print("\nScoring test:")
	var score = word_checker.get_word_score("THE")
	print("  'THE' -> %d points" % score)
	
	print("\n=== Test completed ===")
	
	# Restore main scene and quit
	ProjectSettings.set_setting("application/run/main_scene", "res://scenes/Main.tscn")
	get_tree().quit()

func _load_test_dictionary(word_checker: WordChecker):
	# Manually insert test words
	var test_words = ["THE", "AND", "FOR", "ARE", "BUT", "NOT", "YOU", "ALL", "ABOUT", "AFTER"]
	for word in test_words:
		word_checker.insert_word(word.to_upper())
	
	word_checker.is_loaded = true