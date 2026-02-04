extends Node2D
class_name GridManager

@export var grid_width:  int = 2
@export var grid_height: int = 2
@export var hex_size: float = 48.0
@export var tile_scene: PackedScene

@onready var tiles_canvas = $Tiles
@onready var arrows_canvas = $Arrows

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
	print_grid()
	
	
func print_grid():
	var t = ""
	for x in range(grid_width):
		var dir
		if x % 2:
			dir = -1
		else:
			dir = 1
			
		for y in range(grid_height):
			var tile = columns[x][y]
			t += tile.letter
			
			# if there is a tile above, add it as a neighbour
			if columns[x][y-1]:
				tile.add_neighbour(columns[x][y-1])
			# if there is a tile below, add it as a neighbour
			if (y+1) < grid_height and columns[x][y+1]:
				tile.add_neighbour(columns[x][y+1])
			
			if columns[x-1][y]:
				tile.add_neighbour(columns[x-1][y])

			if grid_width > x+1 and columns[x+1][y]:
				tile.add_neighbour(columns[x+1][y])

			if grid_height > y+dir and columns[x-1][y+dir]:
				tile.add_neighbour(columns[x-1][y+dir])

			if (y+dir) >= 0 and (y+dir) < grid_height \
				and (x+1) < grid_width \
				and columns[x+1][y+dir]:
					tile.add_neighbour(columns[x+1][y+dir])
		t += "\n"
		
	print(t)

	print("2:2 = " + columns[2][2].name + "\n")
	for n in columns[2][2].neighbours:
		print(n.name)
	
func create_hex_tile(q: int, r: int):
	var tile = tile_scene.instantiate()
	tile.hex_radius = hex_size
	tiles_canvas.add_child(tile)
	
	var pos = hex_to_pixel(q, r)
	tile.position = pos
	tile.grid_q = q
	tile.grid_r = r
	tile.letter = get_random_letter()
	tile.name = tile.letter
	
	grid[Vector2(q, r)] = tile
	tile.tile_selected.connect(_on_tile_selected)
	
	return tile

func hex_to_pixel(q: int, r: int) -> Vector2:
	var hex_width  = hex_size * 2.0
	var hex_height = hex_size * sqrt(3.0)
	
	var x = q * hex_width * 0.75
	var y = r * hex_height
	
	if q % 2 == 1:
		y -= hex_height * 0.5
	
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
		recalculate_word()
		update_word_display()
		
		# Draw arrow from previous tile to current tile
		if selected_tiles.size() > 1:
			var previous_tile = selected_tiles[-2]
			draw_arrow(previous_tile, tile)

func deselect_tile(tile: HexTile):
	selected_tiles.erase(tile)
	tile.set_selected(false)
	recalculate_word()
	update_word_display()
	
	# Clear all arrows and redraw them for remaining selected tiles
	clear_arrows()
	redraw_all_arrows()

func is_adjacent_to_last_selected(tile: HexTile) -> bool:
	if selected_tiles.is_empty():
		return true
	
	var last_tile = selected_tiles[-1]

	print("last tile = ", tile)
	print("tile neighbours = ", tile.neighbour_letters())
	
	return last_tile.neighbours.find(tile) > 0

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
	clear_arrows()

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

func draw_arrow(from_tile: HexTile, to_tile: HexTile):
	var arrow = Line2D.new()
	arrow.width = 5.0
	arrow.default_color = Color.WHITE
	arrow.add_point(from_tile.position)
	arrow.add_point(to_tile.position)
	
	# Add arrowhead
	var direction = (to_tile.position - from_tile.position).normalized()
	var arrowhead_length = 15.0
	var arrowhead_angle = deg_to_rad(30)
	
	var head_point1 = to_tile.position - direction.rotated(arrowhead_angle) * arrowhead_length
	var head_point2 = to_tile.position - direction.rotated(-arrowhead_angle) * arrowhead_length
	
	arrow.add_point(head_point1)
	arrow.add_point(to_tile.position)
	arrow.add_point(head_point2)
	
	arrows_canvas.add_child(arrow)

func clear_arrows():
	for child in arrows_canvas.get_children():
		child.queue_free()

func redraw_all_arrows():
	for i in range(1, selected_tiles.size()):
		draw_arrow(selected_tiles[i-1], selected_tiles[i])
