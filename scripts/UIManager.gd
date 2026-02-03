extends Control
class_name UIManager

@onready var word_display: Label = $"../UI/WordDisplay"
@onready var score_label: Label = $"../UI/Score"
@onready var time_label: Label = $"../UI/TimeDisplay"
@onready var submit_button: Button = $"../UI/SubmitButton"
@onready var clear_button: Button = $"../UI/ClearButton"
@onready var words_found_label: Label = $"../UI/WordsFound"

var game_manager: GameManager
var grid_manager: GridManager

func _ready():
	game_manager = get_node("../GameManager")
	grid_manager = get_node("../GridManager")
	
	if submit_button:
		submit_button.pressed.connect(_on_submit_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	
	if game_manager:
		game_manager.score_changed.connect(_on_score_changed)
		game_manager.word_submitted.connect(_on_word_submitted)
		game_manager.game_time_updated.connect(_on_time_updated)

func _on_submit_pressed():
	grid_manager.submit_word()

func _on_clear_pressed():
	grid_manager.clear_selection()

func _on_score_changed(new_score: int):
	if score_label:
		score_label.text = str(new_score)

func _on_word_submitted(word: String, points: int):
	_show_word_feedback(word, points, true)

func _on_time_updated(time: int):
	if time_label:
		var minutes = time / 60
		var seconds = time % 60
		time_label.text = "%02d:%02d" % [minutes, seconds]

func _show_word_feedback(word: String, points: int, is_valid: bool):
	var feedback_label = Label.new()
	add_child(feedback_label)
	feedback_label.text = "%s: +%d" % [word, points] if is_valid else "%s: Invalid" % word
	feedback_label.modulate = Color.GREEN if is_valid else Color.RED
	feedback_label.position = Vector2(100, 100 + words_found_label.get_child_count() * 30)
	
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(feedback_label.queue_free)