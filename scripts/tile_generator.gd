class_name TileGenerator extends Node

@onready var tile_scene = preload("res://scenes/HexTile.tscn")

var grid_manager: GridManager
var hex_size: float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_manager = get_parent()
	hex_size = grid_manager.hex_size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func create_hex_tile(q: int, r: int):
	var tile = tile_scene.instantiate()
	tile.hex_radius = hex_size
	
	var pos = hex_to_pixel(q, r) + Vector2(hex_size * 2, hex_size * 4)
	tile.global_position = pos
	tile.grid_q = q
	tile.grid_r = r
	tile.set_letter(grid_manager.get_random_letter())
	tile.set_type(get_random_type())

	print("GRID: tile ", tile.letter, " at ", pos)
	tile.tile_selected.connect(grid_manager._on_tile_selected)
	tile.drop_animation_completed.connect(grid_manager._on_tile_drop_completed)
	#tile.drop_animation_completed.connect(_cycle_rows())
	
	return tile

func hex_to_pixel(q: int, r: int) -> Vector2:
	var hex_width  = hex_size * 2.0
	var hex_height = hex_size * sqrt(3.0)
	
	var x = q * hex_width * 0.75
	var y = r * hex_height
	
	if q % 2 == 1:
		y -= hex_height * 0.5
	
	return Vector2(x, y)

func get_random_type():
	var t = randf()
	
	if t < 0.1:
		return HexTile.Type.CLOCK
		
	if t > 0.9:
		return HexTile.Type.BONUS
		
	return HexTile.Type.NORMAL
		
