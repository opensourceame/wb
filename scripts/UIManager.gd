extends Control
class_name UIManager

@onready var word_display: Label = $"../UI/WordDisplay"
@onready var score_label: Label = $"../UI/Score"
@onready var time_label: Label = $"../UI/TimeDisplay"
@onready var submit_button: Button = $"../UI/SubmitButton"
@onready var shuffle_button: Button = $"../UI/ShuffleButton"
@onready var clear_button: Button = $"../UI/ClearButton"
@onready var words_found_label: Label = $"../UI/WordsFound"
@onready var word_feedback = $"../UI/WordFeedback"
@onready var feedback_label: Label = %FeedbackLabel

var game_manager: GameManager
var grid_manager: GridManager

func _ready():
	game_manager = get_node("../GameManager")
	grid_manager = get_node("../GridManager")
	
	if submit_button:
		submit_button.pressed.connect(_on_submit_pressed)
	if shuffle_button:
		shuffle_button.pressed.connect(_on_shuffle_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	
	if game_manager:
		game_manager.score_changed.connect(_on_score_changed)
		game_manager.word_submitted.connect(_on_word_submitted)
		game_manager.game_time_updated.connect(_on_time_updated)

func _on_submit_pressed():
	grid_manager.submit_word()

func _on_shuffle_pressed():
	grid_manager.shuffle_tiles()

func _on_clear_pressed():
	grid_manager.clear_selection()

func _on_score_changed(new_score: int):
	if score_label:
		score_label.text = "Score: " + str(new_score)

func _on_word_submitted(word: String, points: int):
	_show_word_feedback(word, points, true)

func _on_time_updated(time: int):
	if time_label:
		var minutes = time / 60
		var seconds = time % 60
		time_label.text = "%02d:%02d" % [minutes, seconds]

func _show_word_feedback(word: String, points: int, is_valid: bool):
	word_feedback.show()
	word_feedback.modulate = Color.WHITE

	feedback_label.text = "%s: +%d" % [word, points] if is_valid else "%s: Invalid" % word	
	
	var tween = create_tween()
	tween.tween_property(word_feedback, "modulate:a", 0.0, 3.0)
	tween.tween_callback(word_feedback.hide)
