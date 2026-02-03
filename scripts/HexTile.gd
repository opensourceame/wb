extends Node2D
class_name HexTile

signal tile_selected(tile: HexTile)

@export var letter: String = "A"
@export var grid_q: int = 0
@export var grid_r: int = 0
@export var hex_radius: float = 32.0

var is_selected: bool = false
var normal_color:   Color = Color.WHITE
var selected_color: Color = Color.DARK_GREEN

func _ready():
	letter = get_random_letter()

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

func _draw():
	var color = selected_color if is_selected else normal_color
	draw_hexagon(Vector2.ZERO, hex_radius, color)
	draw_letter()

func draw_hexagon(center: Vector2, radius: float, color: Color):
	var points = PackedVector2Array()
	for i in range(6):
		var angle = deg_to_rad(60 * i)
		var x = center.x + radius * cos(angle)
		var y = center.y + radius * sin(angle)
		points.append(Vector2(x, y))
	
	draw_colored_polygon(points, color, points)
	#draw_polygon(points, PackedColorArray([Color.BLACK]))

func draw_letter():
	var font = ThemeDB.fallback_font
	var font_size = int(hex_radius * 0.8)
	
	var letter_size = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var letter_pos = Vector2(-letter_size.x / 2, letter_size.y / 3)
	
	draw_string(font, letter_pos, letter, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)

func set_selected(selected: bool):
	is_selected = selected
	queue_redraw()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton and event.pressed:
		tile_selected.emit(self)

func get_grid_position() -> Vector2:
	return Vector2(grid_q, grid_r)
