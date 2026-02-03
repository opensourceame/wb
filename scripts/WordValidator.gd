extends Node
class_name WordValidator

var dictionary: Dictionary = {}

func _ready():
	load_dictionary()

func load_dictionary():
	var file = FileAccess.open("res://data/words.txt", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var words = content.split("\n")
		for word in words:
			word = word.strip_edges().to_upper()
			if word.length() >= 3:
				dictionary[word] = true
		file.close()
	else:
		print("Dictionary file not found. Using basic validation.")

func is_valid_word(word: String) -> bool:
	word = word.strip_edges().to_upper()
	
	if word.length() < 3:
		return false
	
	if dictionary.is_empty():
		return is_english_word_basic(word)
	
	return dictionary.has(word)

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
		dictionary[word] = true

func get_word_score(word: String) -> int:
	word = word.to_upper()
	var letter_scores = {
		"A": 1, "E": 1, "I": 1, "O": 1, "U": 1, "L": 1, "N": 1, "R": 1, "S": 1, "T": 1,
		"D": 2, "G": 2,
		"B": 3, "C": 3, "M": 3, "P": 3,
		"F": 4, "H": 4, "V": 4, "W": 4, "Y": 4,
		"K": 5,
		"J": 8, "X": 8,
		"Q": 10, "Z": 10
	}
	
	var score = 0
	for letter in word:
		score += letter_scores.get(letter, 1)
	
	var length_bonus = 0
	if word.length() >= 5:
		length_bonus = word.length() - 4
	
	return score + length_bonus