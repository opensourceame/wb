extends Node2D
class_name HexTile

enum State { IDLE, SELECTED, HOVER, IN_WORD, APPEARING, DISAPPEARING }
const COLORS = [
	Color.LIGHT_GOLDENROD,  
	Color.DARK_GREEN,
	Color.DARK_GOLDENROD,
	Color.RED,
	Color.BLACK,
	Color(0, 0, 0, 0)
]
signal tile_selected(tile: HexTile)
signal drop_animation_completed(tile: HexTile)

@export var letter: String = "A"
@export var grid_q: int = 0
@export var grid_r: int = 0
@export var hex_radius: float = 128.0

var neighbours: Array = []
var is_selected: bool = false
var outline_color:    Color = Color.DARK_ORANGE
var current_state: int = State.APPEARING
	#set(value):
		#if current_state != value:
			#current_state = value
			##_update_polygon_color()
var touch_scale: float = 1.0  # NEW: Touch animation scale
var hex_points : PackedVector2Array

# Tile dropping animation properties
var is_dropping: bool = false
var drop_start_position: Vector2
var drop_target_position: Vector2
var drop_progress: float = 0.0
var drop_duration: float = 8.0  # 5 seconds to drop one tile height

# Node references
var filled_polygon: Polygon2D
var outline_line: Line2D
var letter_label: Label
	
func _ready():
	letter     = get_random_letter()
	hex_points = generate_polygon_points(hex_radius)
	
	create_filled_polygon()
	create_outline_polygon()
	create_letter_label()
	create_collision_polygon()

	current_state = State.IDLE
	
func create_filled_polygon():
	# create filled polygon
	filled_polygon = Polygon2D.new()
	filled_polygon.polygon = hex_points
	add_child(filled_polygon)

func create_collision_polygon():
	# create collision polygon and attach to CollisionArea
	var collision_poly = CollisionPolygon2D.new()
	collision_poly.polygon = hex_points
	$CollisionArea.add_child(collision_poly)

func create_outline_polygon():
	# create outline using Line2D for proper polyline rendering
	outline_line = Line2D.new()
	
	# Create closed loop by adding first point at the end
	var outline_points = hex_points.duplicate()
	outline_points.append(hex_points[0])
	
	outline_line.points = outline_points
	outline_line.width = 3.0
	outline_line.default_color = outline_color
	outline_line.antialiased = true
	outline_line.joint_mode = Line2D.LINE_JOINT_ROUND
	#outline_line.cap_mode = Line2D.LINE_CAP_ROUND
	add_child(outline_line)

func disappear():
	current_state = State.DISAPPEARING
	outline_line.queue_free()
	var t = Timer.new()
	t.wait_time = 0.5
	t.timeout.connect(queue_free)
	t.start()
	
func set_validation_color(color: Color):
	#validation_color = color
	outline_line.default_color = color
		
func create_letter_label():
	# create label for letter
	letter_label = Label.new()
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter_label.position = Vector2(0, 0)
	letter_label.size = Vector2(hex_radius * 2, hex_radius * 2)
	letter_label.position -= letter_label.size / 2
	var font_size = int(hex_radius * 0.8)
	letter_label.add_theme_font_size_override("font_size", font_size)
	letter_label.add_theme_color_override("font_color", Color.BLACK)
	add_child(letter_label)
	
func add_neighbour(tile: HexTile):
	neighbours.append(tile)
	
func neighbour_letters():
	var t = ""
	for n in neighbours:
		t += n.letter + ' '
		
	return t
		
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

func _physics_process(delta):
	# Smooth color transition
	var target_color = COLORS[current_state]
	
	if current_state == State.DISAPPEARING:
		modulate = modulate.lerp(COLORS[State.DISAPPEARING], delta * 3)
		#queue_free()
	else:
		if not target_color == filled_polygon.color:
			filled_polygon.color = filled_polygon.color.lerp(target_color, delta * 10.0)
	
	
	# Handle tile dropping animation
	if is_dropping:
		drop_progress += delta / drop_duration
		if drop_progress >= 1.0:
			drop_progress = 1.0
			is_dropping = false
			position = drop_target_position
			drop_animation_completed.emit(self)
		else:
			# Smooth easing function (ease-in-out)
			var t = drop_progress
			var eased_t = t * t * (3.0 - 2.0 * t)  # Smoothstep
			position = drop_start_position.lerp(drop_target_position, eased_t)

func _update_polygon_color():
	# Immediate color update for instant visual feedback
	#filled_polygon.color = COLORS[current_state]
	pass
	
func generate_polygon_points(radius: float):
	var center = Vector2.ZERO
	var points = PackedVector2Array()
	for i in range(6):
		var angle = deg_to_rad(60 * i)
		var x = center.x + radius * cos(angle)
		var y = center.y + radius * sin(angle)
		points.append(Vector2(x, y))
	return points

func set_letter(let):
	letter = let
	name   = let
	letter_label.text = letter
		
func set_idle():
	current_state = State.IDLE
	
func set_selected():
	current_state = State.SELECTED
	print("selected ", self)
	
func set_in_word():
	current_state = State.IN_WORD

func set_hover():
	current_state = State.HOVER

func clear_hover():
	if current_state == State.HOVER:
		current_state = State.IDLE
	

# Touch hover effects using state management
func _input(event):
	if event is InputEventScreenTouch:
		var global_pos = event.position
		if _is_point_inside_hex(global_pos):
			if event.pressed:
				enter_hover_state()
			else:
				exit_hover_state()
	
	# Handle multi-touch scenarios
	elif event is InputEventScreenDrag:
		# This is handled in area_2d_input_event for better performance
		pass

func enter_hover_state():
	if current_state == State.IDLE:
		set_hover()
		
	# Add subtle scale animation for touch feedback
	if current_state == State.HOVER:
		touch_scale = 1.1
	else:
		touch_scale = 1.0
	
	# Apply scale transform
	scale = Vector2(touch_scale, touch_scale)

func exit_hover_state():
	if current_state == State.HOVER:
		set_idle()
		
	touch_scale = 1.0
	scale = Vector2(touch_scale, touch_scale)

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if current_state == State.DISAPPEARING:
		return
		
	# Handle mouse clicks
	if event is InputEventMouseButton and event.pressed:
		tile_selected.emit(self)
	
	# Handle touch events
	elif event is InputEventScreenTouch and event.pressed:
		tile_selected.emit(self)
		enter_hover_state()
	elif event is InputEventScreenTouch and not event.pressed:
		exit_hover_state()
	
	# Handle touch/drag events for continuous selection
	elif event is InputEventScreenDrag:
		# Convert screen position to global position
		var global_pos = event.position
		# Check if this touch/drag is over this tile
		if _is_point_inside_hex(global_pos):
			tile_selected.emit(self)
			enter_hover_state()
		else:
			exit_hover_state()

func _is_point_inside_hex(point: Vector2) -> bool:
	# Convert screen point to local coordinates
	var local_point = to_local(point)
	var distance = local_point.length()
	return distance <= hex_radius

func get_grid_position() -> Vector2:
	return Vector2(grid_q, grid_r)

func start_drop_animation():
	# Calculate one tile height downward
	var hex_height = hex_radius * sqrt(3.0)
	drop_start_position  = position
	drop_target_position = position + Vector2(0, hex_height)
	drop_progress = 0.0
	is_dropping = true

func stop_drop_animation():
	is_dropping = false
	drop_progress = 0.0
