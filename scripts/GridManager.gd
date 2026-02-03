extends Node2D
class_name GridManager

@export var grid_width:  int = 2
@export var grid_height: int = 2
@export var hex_size: float = 48.0
@export var tile_scene: PackedScene

var grid: Dictionary = {}
var selected_tiles: Array[HexTile] = []
var current_word: String = ""
var columns = []
var rows    = []

func _ready():
	if tile_scene == null:
		tile_scene = preload("res://scenes/HexTile.tscn")
	create_hex_grid()

func create_hex_grid():
	for q in range(grid_width):
		columns.append([])
		for r in range(grid_height):
			var tile = create_hex_tile(q, r)
			columns[q].append(tile)
	print("GRID: created grid")
	
func create_hex_tile(q: int, r: int):
	var tile = tile_scene.instantiate()
	tile.hex_radius = hex_size
	add_child(tile)
	
	var pos = hex_to_pixel(q, r)
	tile.position = pos
	tile.grid_q = q
	tile.grid_r = r
	tile.letter = get_random_letter()
	
	grid[Vector2(q, r)] = tile
	tile.tile_selected.connect(_on_tile_selected)
	
	return tile

func hex_to_pixel(q: int, r: int) -> Vector2:
	var hex_width  = hex_size * 2.0
	var hex_height = hex_size * sqrt(3.0)
	
	var x = q * hex_width * 0.75
	var y = r * hex_height
	
	if q % 2 == 1:
		y += hex_height * 0.5
	
	return Vector2(x, y)

func get_random_letter() -> String:
	var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var weights = [10, 2, 2, 4, 15, 2, 3, 6, 8, 1, 1, 4, 3, 6, 10, 2, 1, 6, 6, 8, 4, 2, 2, 1, 2, 1]
	
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
	var dq = tile.grid_q - last_tile.grid_q
	var dr = tile.grid_r - last_tile.grid_r
	
	if dq == 0 and abs(dr) == 1:
		return true
	
	if abs(dq) == 1:
		if last_tile.grid_q % 2 == 0:
			return dr >= 0 and dr <= 1
		else:
			return dr >= -1 and dr <= 0
	
	return false

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
