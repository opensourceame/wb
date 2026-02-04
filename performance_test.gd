extends Node

# Performance test for 68k word dictionary
func _ready():
	print("=== Performance Test: 68k Word Dictionary ===")
	
	var test_start = Time.get_ticks_msec()
	var word_checker = WordChecker.new()
	add_child(word_checker)
	
	# Wait for loading to complete
	await word_checker.dictionary_loaded
	var load_time = Time.get_ticks_msec() - test_start
	
	print("Dictionary load time: %d ms" % load_time)
	print(word_checker.get_dictionary_stats())
	
	# Performance tests
	test_prefix_validation_speed(word_checker)
	test_word_validation_speed(word_checker)
	
	get_tree().quit()

func test_prefix_validation_speed(word_checker: WordChecker):
	print("\n=== Prefix Validation Speed Test ===")
	
	var test_prefixes = ["TH", "THE", "HEL", "WOR", "ABC", "XYZ"]
	var iterations = 1000
	
	var start_time = Time.get_ticks_msec()
	
	for i in range(iterations):
		for prefix in test_prefixes:
			word_checker.is_valid_prefix(prefix)
	
	var total_time = Time.get_ticks_msec() - start_time
	var avg_time = float(total_time) / (iterations * test_prefixes.size())
	
	print("Total time for %d prefix checks: %d ms" % [iterations * test_prefixes.size(), total_time])
	print("Average time per prefix check: %.3f ms" % avg_time)

func test_word_validation_speed(word_checker: WordChecker):
	print("\n=== Word Validation Speed Test ===")
	
	var test_words = ["THE", "HELLO", "WORLD", "COMPUTER", "INVALID123"]
	var iterations = 500
	
	var start_time = Time.get_ticks_msec()
	
	for i in range(iterations):
		for word in test_words:
			word_checker.is_valid_word(word)
	
	var total_time = Time.get_ticks_msec() - start_time
	var avg_time = float(total_time) / (iterations * test_words.size())
	
	print("Total time for %d word checks: %d ms" % [iterations * test_words.size(), total_time])
	print("Average time per word check: %.3f ms" % avg_time)