extends Node
class_name WordChecker

class TrieNode:
	var children: Dictionary = {}
	var is_word: bool = false
	
	# Memory optimization: reuse common nodes
	static func get_optimized_char_key(char: String) -> String:
		return char  # Direct character access for performance

var root: TrieNode
var is_loaded: bool = false
var loading_thread: Thread
var letter_scores: Dictionary = {}

signal dictionary_loaded
signal loading_progress(progress: float)

func _ready():
	letter_scores = {
		"A": 1, "E": 1, "I": 1, "O": 1, "U": 1, "L": 1, "N": 1, "R": 1, "S": 1, "T": 1,
		"D": 2, "G": 2,
		"B": 3, "C": 3, "M": 3, "P": 3,
		"F": 4, "H": 4, "V": 4, "W": 4, "Y": 4,
		"K": 5,
		"J": 8, "X": 8,
		"Q": 10, "Z": 10
	}
	root = TrieNode.new()
	print("Loading 68k word dictionary...")
	load_dictionary_async()

func load_dictionary_async():
	if loading_thread:
		loading_thread.wait_to_finish()
	
	loading_thread = Thread.new()
	loading_thread.start(_load_dictionary_worker)

func _load_dictionary_worker():
	var file = FileAccess.open("res://data/words.txt", FileAccess.READ)
	if not file:
		print("Dictionary file not found. Using basic validation.")
		return
	
	# Optimized: Read entire file at once (good for 646KB file)
	var content = file.get_as_text()
	file.close()
	
	var words = content.split("\n")
	var total_words = words.size()
	var processed = 0
	
	for word in words:
		word = word.strip_edges().to_upper()
		if word.length() >= 3:
			insert_word(word)
		
		processed += 1
		if processed % 10000 == 0:  # Very infrequent progress updates
			var progress = float(processed) / float(total_words)
			call_deferred("emit_signal", "loading_progress", progress)
	
	call_deferred("_on_loading_complete")

func _on_loading_complete():
	is_loaded = true
	if loading_thread:
		loading_thread.wait_to_finish()
		loading_thread = null
	print("Dictionary loaded successfully! Real-time validation is now active.")
	dictionary_loaded.emit()

func insert_word(word: String):
	var node = root
	var chars = word.to_ascii_buffer()  # Faster than string iteration
	
	for i in range(chars.size()):
		var char_code = chars[i]
		var char_str = char(char_code)
		if not node.children.has(char_str):
			node.children[char_str] = TrieNode.new()
		node = node.children[char_str]
	node.is_word = true

func is_valid_word(word: String) -> bool:
	word = word.strip_edges().to_upper()
	
	if word.length() < 3:
		return false
	
	if not is_loaded:
		return is_english_word_basic(word)
	
	return _search_word(word)

func is_valid_prefix(prefix: String) -> bool:
	prefix = prefix.strip_edges().to_upper()
	
	if prefix.length() < 1:
		return true
	
	if not is_loaded:
		return true
	
	# Early optimization: very long prefixes (15+ chars) are rarely valid in English
	if prefix.length() > 15:
		return false
	
	return _search_prefix(prefix)

func _search_word(word: String) -> bool:
	var node = root
	for char in word:
		if not node.children.has(char):
			return false
		node = node.children[char]
	return node.is_word

func _search_prefix(prefix: String) -> bool:
	var node = root
	for char in prefix:
		if not node.children.has(char):
			return false
		node = node.children[char]
	return true

func is_english_word_basic(word: String) -> bool:
	var common_patterns = [
		"TH", "HE", "IN", "ER", "AN", "RE", "ED", "ND", "TO", "EN",
		"ES", "OR", "TI", "HI", "ST", "AR", "TE", "AS", "ON", "AT"
	]
	
	var common_vowels = ["A", "E", "I", "O", "U"]
	var has_vowel = false
	
	for vowel in common_vowels:
		if word.contains(vowel):
			has_vowel = true
			break
	
	if word.length() > 3 and not has_vowel and not word in ["MY", "BY", "SHY"]:
		return false
	
	for pattern in common_patterns:
		if word.contains(pattern):
			return true
	
	if word.length() <= 4:
		return true
	
	var consecutive_consonants = 0
	var consecutive_vowels = 0
	
	for i in range(word.length()):
		var char = word[i]
		if char in common_vowels:
			consecutive_vowels += 1
			consecutive_consonants = 0
		else:
			consecutive_consonants += 1
			consecutive_vowels = 0
		
		if consecutive_consonants > 3 or consecutive_vowels > 3:
			return false
	
	return true

func add_word_to_dictionary(word: String):
	word = word.strip_edges().to_upper()
	if word.length() >= 3:
		insert_word(word)

func get_word_score(word: String) -> int:
	word = word.to_upper()
	var score = 0
	for letter in word:
		score += letter_scores.get(letter, 1)
	
	var length_bonus = 0
	if word.length() >= 5:
		length_bonus = word.length() - 4
	
	return score + length_bonus

func get_dictionary_stats() -> Dictionary:
	var word_count = _count_words_recursive(root)
	return {
		"total_words": word_count,
		"is_loaded": is_loaded,
		"memory_estimate_kb": word_count * 0.2  # Rough estimate
	}

func _count_words_recursive(node: TrieNode) -> int:
	var count = 1 if node.is_word else 0
	for child in node.children.values():
		count += _count_words_recursive(child)
	return count

func _exit_tree():
	if loading_thread and loading_thread.is_alive():
		loading_thread.wait_to_finish()
