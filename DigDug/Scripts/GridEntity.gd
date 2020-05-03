extends Area2D
class_name GridEntity

# Simple template class for anything that needs access to the tilemap

var LEVEL : LevelHandler
var GRID : Vector2
var start_pos : Vector2

func _ready():
	if is_inside_tree():
		add_to_group("grid_entities")
	
	start_pos = position

func destroy_self():
	if is_inside_tree():
		remove_from_group("grid_entities")
	queue_free()

func set_level_handler(map : LevelHandler):
	self.LEVEL = map
	self.GRID = map.GROUND_MAP.cell_size
	print("Setting level handler \"", (map as Node).name, "\" for ", self.name)

func reset_position():
	position = start_pos
