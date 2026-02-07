extends Node
class_name GameManager

signal score_changed(new_score: int)
signal word_submitted(word: String, points: int)
signal game_time_updated(time: int)
signal prefix_validation_changed(is_valid: bool, current_word: String)
signal word_building_started()
signal word_building_ended(word: String)

var score: int = 0
var words_found: Array[String] = []
var game_time: int = 120.0
var is_game_active: bool = true
var word_checker: WordChecker

@onready var grid_manager: GridManager = get_tree().current_scene.get_node("GridManager")

func _ready():
	word_checker = WordChecker.new()
	add_child(word_checker)
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	if is_game_active:
		game_time -= 1
		game_time_updated.emit(game_time)

func submit_word(word: String):
	printerr("GAME: submit word ", word)
	if not is_game_active:
		return
	
	word = word.strip_edges().to_upper()
	
	if word.length() < 3:
		return invalid_word_submitted()
	
	if words_found.has(word):
		return invalid_word_submitted()
		
	if not word_checker.is_valid_word(word):
		return invalid_word_submitted()
		
	var points = word_checker.get_word_score(word)
	add_score(points)
	words_found.append(word)
	word_submitted.emit(word, points)
	
	#grid_manager.clear_selection()
	
	$"../Sounds/Kaching".play()
	
	return true

func invalid_word_submitted():
	$"../Sounds/ShortBeep".play()
	
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
		"score":        score,
		"words_found":  words_found.size(),
		"total_words":  words_found,
		"time_elapsed": game_time
	}

func get_time_string() -> String:
	var minutes = game_time / 60
	var seconds = game_time % 60
	return "%02d:%02d" % [minutes, seconds]

func _input(event):
	# Test tile dropping animation with 'D' key
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_D:
			print("Starting tile drop animation...")
			grid_manager.start_tile_drop_animation()
		elif event.keycode == KEY_S:
			print("Stopping tile drop animation...")
			grid_manager.stop_tile_drop_animation()

# NEW: Real-time validation methods for GridManager
func on_prefix_validation_changed(is_valid: bool, current_word: String):
	prefix_validation_changed.emit(is_valid, current_word)

func on_word_building_started():
	word_building_started.emit()

func on_word_building_ended(word: String):
	word_building_ended.emit(word)
