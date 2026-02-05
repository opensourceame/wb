extends Node2D
class_name GridManager

# NEW: Signals for real-time validation
signal word_building_started()
signal word_building_ended(word: String)

@export var grid_width:  int = 2
@export var grid_height: int = 2
@export var hex_size: float = 48.0
@export var tile_scene: PackedScene

@onready var game_manager = get_tree().current_scene.get_node('GameManager')
@onready var tiles_canvas = $Tiles
@onready var arrows_canvas = $Arrows

# Access to game systems
var word_checker: WordChecker

# Touch gesture tracking
var touch_start_time: float = 0
var touch_start_pos: Vector2
var is_long_press: bool = false
var long_press_timer: Timer

var grid: Dictionary = {}
var selected_tiles: Array[HexTile] = []
var current_word: String = ""
var columns = []
var rows    = []
var use_particles: bool = true
var particle_streams: Array[CPUParticles2D] = []

# Tile dropping and row management
var tiles_dropping: int = 0
var is_row_cycle_active: bool = false

func _ready():
	if tile_scene == null:
		tile_scene = preload("res://scenes/HexTile.tscn")
	
	word_checker = game_manager.word_checker
	
	# Setup long press timer for touch submit
	long_press_timer = Timer.new()
	add_child(long_press_timer)
	long_press_timer.wait_time = 0.5  # 500ms for long press
	long_press_timer.one_shot = true
	long_press_timer.timeout.connect(_on_long_press)
	
	create_hex_grid()

func create_hex_grid():
	for q in range(grid_width):
		columns.append([])
		for r in range(grid_height):
			var tile = create_hex_tile(q, r)
			columns[q].append(tile)
		
	print("GRID: created grid")
	print_grid()
	
	
func shuffle_tiles():
	# Collect all letters from current tiles
	var all_letters = []
	for q in range(grid_width):
		for r in range(grid_height):
			all_letters.append(columns[q][r].letter)
	
	# Shuffle the letters array
	all_letters.shuffle()
	
	# Reassign shuffled letters to tiles
	var letter_index = 0
	for q in range(grid_width):
		for r in range(grid_height):
			columns[q][r].set_letter(all_letters[letter_index])
			letter_index += 1
	
	# Clear any current selection
	clear_selection()
	
	print("Tiles shuffled!")

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
	tile.set_letter(get_random_letter())
	
	grid[Vector2(q, r)] = tile
	tile.tile_selected.connect(_on_tile_selected)
	tile.drop_animation_completed.connect(_on_tile_drop_completed)
	
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
	if not is_adjacent_to_last_selected(tile):
		return
		
	selected_tiles.append(tile)
	tile.set_selected()
	current_word += tile.letter
	recalculate_word()
	
	# NEW: Real-time prefix validation
	update_prefix_validation()
	
	# Emit signals for word building tracking
	if selected_tiles.size() == 1:
		word_building_started.emit()
	if game_manager:
		game_manager.on_word_building_started()
	
	update_word_display()
	
	# Create visual connection from previous tile to current tile
	if selected_tiles.size() > 1:
		var previous_tile = selected_tiles[-2]
		if use_particles:
			create_particle_stream(previous_tile, tile)
		else:
			draw_arrow(previous_tile, tile)

func deselect_tile(tile: HexTile):
	if not selected_tiles[-1] == tile:
		printerr("tried to deselect tile which isn't the last")
		return

	selected_tiles.erase(tile)
	if not particle_streams.is_empty():
		if particle_streams[-1]:
			particle_streams[-1].call_deferred("queue_free")
			
	tile.set_idle()
	recalculate_word()
	
	# NEW: Update validation after deselecting
	update_prefix_validation()
	
	update_word_display()
	
	# Clear all visual connections and redraw them for remaining selected tiles
	if use_particles:
		redraw_all_particles()
	else:
		clear_arrows()
		redraw_all_arrows()

func is_adjacent_to_last_selected(tile: HexTile) -> bool:
	if selected_tiles.is_empty():
		return true
	
	var last_tile = selected_tiles[-1]

	print("last tile = ", last_tile)
	print("last tile neighbours = ", last_tile.neighbour_letters())
	
	return last_tile.neighbours.find(tile) >= 0

func recalculate_word():
	current_word = ""
	for tile in selected_tiles:
		current_word += tile.letter
		
func update_word_display():
	%WordDisplay.text = current_word
	
	if !game_manager.words_found.has(current_word) and game_manager.word_checker.is_valid_word(current_word):
		highlight_valid_word()
		
func highlight_valid_word():
	for tile in selected_tiles:
		tile.set_in_word()

# NEW: Real-time prefix validation
func update_prefix_validation():
	if not word_checker:
		return
		
	# Check if current word is a valid prefix
	var is_valid_prefix = word_checker.is_valid_prefix(current_word)
	
	# Update visual feedback for tiles
	update_tile_validation_feedback(is_valid_prefix)
	
	# Update word display color
	update_word_display_color(is_valid_prefix)
	
	# Emit signals for real-time validation feedback
	if game_manager:
		game_manager.on_prefix_validation_changed(is_valid_prefix, current_word)

func update_tile_validation_feedback(is_valid_prefix: bool):
	# Update the color of selected tiles based on prefix validity
	var feedback_color = Color.WHITE if is_valid_prefix else Color.RED
	
	for tile in selected_tiles:
		# Only update the outline/highlight, not the base tile color
		tile.set_validation_color(feedback_color)

func update_word_display_color(is_valid_prefix: bool):
	if %WordDisplay:
		var display_color = Color.WHITE if is_valid_prefix else Color.RED
		%WordDisplay.modulate = display_color

func clear_selection():
	for tile in selected_tiles:
		tile.set_idle()
	selected_tiles.clear()
	current_word = ""
	update_word_display()
	clear_arrows()

func _input(event):
	# Handle keyboard/gamepad input
	if event.is_action_pressed("ui_accept"):
		submit_word()
	elif event.is_action_pressed("ui_cancel"):
		clear_selection()
	
	# Handle touch gestures
	elif event is InputEventScreenTouch and event.pressed:
		# Start tracking touch for potential long press
		touch_start_time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["microsecond"] / 1000000.0
		touch_start_pos = event.position
		is_long_press = false
		long_press_timer.start()
		
	elif event is InputEventScreenTouch and not event.pressed:
		# Touch released
		if is_long_press and current_word.length() >= 3:
			# Long press - submit word
			submit_word()
		else:
			# Quick tap outside tiles - clear selection
			var touched_tile = get_tile_at_position(event.position)
			if not touched_tile:
				clear_selection()
		
		long_press_timer.stop()
	
	elif event is InputEventScreenDrag:
		# Touch drag is handled by individual tiles
		pass

func submit_word():
	if current_word.length() < 3:
		return 

	game_manager.submit_word(current_word)
		
	# Emit word building ended signal
	game_manager.on_word_building_ended(current_word)
	
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

# Particle System Functions
func create_particle_stream(from_tile: HexTile, to_tile: HexTile):
	var particles = CPUParticles2D.new()
	particles.position = from_tile.position
	
	# Calculate direction and distance
	var direction = (to_tile.position - from_tile.position).normalized()
	var distance = from_tile.position.distance_to(to_tile.position) - 20
	
	# Basic particle setup
	particles.emitting = true
	particles.visible = true
	particles.amount = 10
	particles.lifetime = 1.0  # Longer lifetime for visibility
	particles.explosiveness = 0.0  # Continuous emission
	particles.fixed_fps =100.0
	
	# Gold/yellow gradient colors
	particles.color = Color.GOLD
	particles.color_ramp = Gradient.new()
	particles.color_ramp.add_point(0.0, Color.YELLOW)
	particles.color_ramp.add_point(0.5, Color.GOLD)
	particles.color_ramp.add_point(1.0, Color.ORANGE)
	
	# Energy stream visual properties
	particles.direction = Vector2(1, 0)  # Will be rotated
	particles.spread = 2.0  # Slightly wider stream for visibility
	particles.initial_velocity_min = distance / particles.lifetime * 0.8
	particles.initial_velocity_max = distance / particles.lifetime * 1.2
	
	# Particle size and shape
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 7.0
	#particles.scale_amount_random = 0.5
	
	# Gravity and physics
	particles.gravity = Vector2.ZERO
	#particles.damping = 0.0
	#particles.angular_velocity = 0.0
	#particles.angular_velocity_random = 0.0
	
	# Rotate particles to face the direction
	particles.rotation = direction.angle()
	
	# Add to canvas and tracking array
	arrows_canvas.add_child(particles)
	particle_streams.append(particles)
	
	# Start emission and auto-cleanup
	particles.restart()
	
	# Auto-cleanup after particles finish
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = particles.lifetime + 1.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): 
		particles.emitting = false
		particles.queue_free()
		particle_streams.erase(particles)
	)
	add_child(cleanup_timer)
	#cleanup_timer.start()

func clear_particles():
	for stream in particle_streams:
		stream.emitting = false
		stream.queue_free()
	particle_streams.clear()
	
	# Also clear any remaining Line2D arrows
	for child in arrows_canvas.get_children():
		if child is Line2D:
			child.queue_free()

func redraw_all_particles():
	for i in range(1, selected_tiles.size()):
		create_particle_stream(selected_tiles[i-1], selected_tiles[i])

# Fallback toggle function (can be called from UI or debug)
func _on_long_press():
	is_long_press = true
	print("Long press detected - word can be submitted")

func get_tile_at_position(screen_pos: Vector2) -> HexTile:
	# Convert screen position to world space
	var world_pos = get_global_transform().inverse() * screen_pos
	
	# Check each tile to see if position is within hex
	for tile in tiles_canvas.get_children():
		var local_pos = tile.to_local(world_pos)
		var distance = local_pos.length()
		if distance <= tile.hex_radius:
			return tile
	
	return null

func set_use_particles(enabled: bool):
	use_particles = enabled
	if not enabled:
		clear_particles()
		redraw_all_arrows()
	else:
		clear_arrows()
		redraw_all_particles()

func start_tile_drop_animation():
	if is_row_cycle_active:
		print("Row cycle already in progress, skipping...")
		return
		
	is_row_cycle_active = true
	tiles_dropping = 0
	
	# Start drop animation on all tiles in the grid
	for q in range(grid_width):
		for r in range(grid_height):
			if columns[q] and columns[q][r]:
				columns[q][r].start_drop_animation()
				tiles_dropping += 1
	
	print("Started drop animation on ", tiles_dropping, " tiles")

func stop_tile_drop_animation():
	# Stop drop animation on all tiles in the grid
	for q in range(grid_width):
		for r in range(grid_height):
			if columns[q] and columns[q][r]:
				columns[q][r].stop_drop_animation()
	
	is_row_cycle_active = false
	tiles_dropping = 0

func _on_tile_drop_completed(tile: HexTile):
	tiles_dropping -= 1
	
	if tiles_dropping == 0 and is_row_cycle_active:
		print("All tiles completed dropping - cycling rows...")
		_cycle_rows()

func _cycle_rows():
	print("🔄 Starting row cycle process...")
	
	# Remove bottom row and create new top row
	var bottom_row_tiles = []
	var bottom_row_letters = []
	
	# Collect bottom row tiles (row = grid_height - 1)
	for q in range(grid_width):
		if columns[q] and columns[q][grid_height - 1]:
			bottom_row_tiles.append(columns[q][grid_height - 1])
			bottom_row_letters.append(columns[q][grid_height - 1].letter)
	
	print("🗑️ Removing bottom row with letters: ", bottom_row_letters)
	
	# Remove bottom row tiles
	for tile in bottom_row_tiles:
		tile.queue_free()
	
	# Shift all tiles down by one row
	print("⬇️ Shifting tiles down by one row...")
	for r in range(grid_height - 2, -1, -1):  # Start from second-to-last row, go up
		for q in range(grid_width):
			if columns[q] and columns[q][r]:
				var tile = columns[q][r]
				tile.grid_r = r + 1  # Update grid coordinate
				
				# Update grid dictionary reference
				grid.erase(Vector2(q, r))
				grid[Vector2(q, r + 1)] = tile
				
				# Update column array
				columns[q][r + 1] = tile
	
	# Create new top row (row = 0)
	print("⬆️ Creating new top row...")
	var new_row_letters = []
	for q in range(grid_width):
		var new_tile = create_hex_tile(q, 0)
		columns[q][0] = new_tile
		grid[Vector2(q, 0)] = new_tile
		new_row_letters.append(new_tile.letter)
	
	print("✨ New top row letters: ", new_row_letters)
	
	# Update all tile positions to match new grid coordinates
	print("📍 Updating tile positions...")
	_update_all_tile_positions()
	
	# Rebuild neighbour connections
	print("🔗 Rebuilding neighbour connections...")
	_rebuild_neighbour_connections()
	
	# Clear any current selection since tiles changed
	clear_selection()
	
	is_row_cycle_active = false
	print("✅ Row cycle completed successfully!")

func _update_all_tile_positions():
	# Update visual position of all tiles to match their grid coordinates
	for q in range(grid_width):
		for r in range(grid_height):
			if columns[q] and columns[q][r]:
				var tile = columns[q][r]
				var new_pos = hex_to_pixel(q, r)
				tile.position = new_pos

func _rebuild_neighbour_connections():
	# Clear all existing neighbours
	for q in range(grid_width):
		for r in range(grid_height):
			if columns[q] and columns[q][r]:
				columns[q][r].neighbours.clear()
	
	# Rebuild neighbour connections based on new positions
	_rebuild_neighbour_connections_helper()

func _rebuild_neighbour_connections_helper():
	# Use the existing print_grid logic to rebuild neighbours
	for x in range(grid_width):
		var dir
		if x % 2:
			dir = -1
		else:
			dir = 1
			
		for y in range(grid_height):
			# Skip if this position doesn't have a tile
			if not columns[x] or y >= columns[x].size() or not columns[x][y]:
				continue
				
			var tile = columns[x][y]
			
			# if there is a tile above, add it as a neighbour
			if y > 0 and columns[x] and y < columns[x].size() and columns[x][y-1]:
				tile.add_neighbour(columns[x][y-1])
			# if there is a tile below, add it as a neighbour
			if (y+1) < grid_height and columns[x] and (y+1) < columns[x].size() and columns[x][y+1]:
				tile.add_neighbour(columns[x][y+1])
			
			if x > 0 and columns[x-1] and y < columns[x-1].size() and columns[x-1][y]:
				tile.add_neighbour(columns[x-1][y])

			if grid_width > x+1 and columns[x+1] and y < columns[x+1].size() and columns[x+1][y]:
				tile.add_neighbour(columns[x+1][y])

			if grid_height > y+dir and x > 0 and columns[x-1] and (y+dir) < columns[x-1].size() and columns[x-1][y+dir]:
				tile.add_neighbour(columns[x-1][y+dir])

			if (y+dir) >= 0 and (y+dir) < grid_height \
				and (x+1) < grid_width \
				and columns[x+1] and (y+dir) < columns[x+1].size() \
				and columns[x+1][y+dir]:
					tile.add_neighbour(columns[x+1][y+dir])
