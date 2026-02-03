extends Node2D
class_name GridManager

@export var grid_width: int = 3
@export var grid_height: int = 3
@export var hex_size: float = 64.0
@export var tile_scene: PackedScene

var grid: Dictionary = {}
var selected_tiles: Array[HexTile] = []
var current_word: String = ""

func _ready():
	if tile_scene == null:
		tile_scene = preload("res://scenes/HexTile.tscn")
	create_hex_grid()

func create_hex_grid():
	for q in range(-grid_width / 2, grid_width / 2 + 1):
		for r in range(-grid_height / 2, grid_height / 2 + 1):
			if abs(q + r) <= grid_height / 2:
				create_hex_tile(q, r)

func create_hex_tile(q: int, r: int):
	var tile = tile_scene.instantiate()
	add_child(tile)
	
	var pos = hex_to_pixel(q, r)
	tile.position = pos
	tile.grid_q = q
	tile.grid_r = r
	tile.letter = get_random_letter()
	
	grid[Vector2(q, r)] = tile
	tile.tile_selected.connect(_on_tile_selected)

func hex_to_pixel(q: int, r: int) -> Vector2:
	var x = hex_size * (3.0/2.0 * q)
	var y = hex_size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	return Vector2(x, y)

func get_random_letter() -> String:
	var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var weights = [8, 2, 2, 4, 12, 2, 3, 6, 8, 1, 1, 4, 3, 6, 8, 2, 1, 6, 6, 8, 4, 2, 2, 1, 2, 1]
	
	var total_weight = 0
	for weight in weights:
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0
	
	for i in range(letters.length()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return letters[i]
	
	return "E"

func _on_tile_selected(tile: HexTile):
	if selected_tiles.has(tile):
		deselect_tile(tile)
	else:
		select_tile(tile)

func select_tile(tile: HexTile):
	if is_adjacent_to_last_selected(tile):
		selected_tiles.append(tile)
		tile.set_selected(true)
		current_word += tile.letter
		update_word_display()

func deselect_tile(tile: HexTile):
	selected_tiles.erase(tile)
	tile.set_selected(false)
	recalculate_word()
	update_word_display()

func is_adjacent_to_last_selected(tile: HexTile) -> bool:
	if selected_tiles.is_empty():
		return true
	
	var last_tile = selected_tiles[-1]
	var dq = abs(tile.grid_q - last_tile.grid_q)
	var dr = abs(tile.grid_r - last_tile.grid_r)
	var ds = abs((tile.grid_q + tile.grid_r) - (last_tile.grid_q + last_tile.grid_r))
	
	return (dq <= 1 and dr <= 1 and ds <= 1)

func recalculate_word():
	current_word = ""
	for tile in selected_tiles:
		current_word += tile.letter

func update_word_display():
	var word_label = $UI/WordDisplay
	if word_label:
		word_label.text = current_word

func clear_selection():
	for tile in selected_tiles:
		tile.set_selected(false)
	selected_tiles.clear()
	current_word = ""
	update_word_display()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		submit_word()
	elif event.is_action_pressed("ui_cancel"):
		clear_selection()

func submit_word():
	if current_word.length() >= 3:
		var game_manager = get_node_or_null("../GameManager")
		if game_manager:
			game_manager.submit_word(current_word)
		clear_selection()
