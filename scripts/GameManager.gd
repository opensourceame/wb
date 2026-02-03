extends Node
class_name GameManager

signal score_changed(new_score: int)
signal word_submitted(word: String, points: int)
signal game_time_updated(time: int)

var score: int = 0
var words_found: Array[String] = []
var game_time: int = 0
var is_game_active: bool = true
var word_validator: WordValidator

@onready var grid_manager: GridManager = $"../GridManager"

func _ready():
	word_validator = WordValidator.new()
	add_child(word_validator)
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	if is_game_active:
		game_time += 1
		game_time_updated.emit(game_time)

func submit_word(word: String):
	if not is_game_active:
		return
	
	word = word.strip_edges().to_upper()
	
	if word.length() < 3:
		return
	
	if words_found.has(word):
		return
	
	if word_validator.is_valid_word(word):
		var points = word_validator.get_word_score(word)
		add_score(points)
		words_found.append(word)
		word_submitted.emit(word, points)
		
		grid_manager.clear_selection()
		
		return true
	else:
		return false

func add_score(points: int):
	score += points
	score_changed.emit(score)

func clear_selection():
	grid_manager.clear_selection()

func reset_game():
	score = 0
	words_found.clear()
	game_time = 0
	is_game_active = true
	score_changed.emit(score)
	game_time_updated.emit(game_time)
	
	if grid_manager:
		grid_manager.clear_selection()

func pause_game():
	is_game_active = false

func resume_game():
	is_game_active = true

func get_game_stats() -> Dictionary:
	return {
		"score": score,
		"words_found": words_found.size(),
		"total_words": words_found,
		"time_elapsed": game_time
	}

func get_time_string() -> String:
	var minutes = game_time / 60
	var seconds = game_time % 60
	return "%02d:%02d" % [minutes, seconds]
