extends GridEntity

const SPEED = 128
var travel_dir : Vector2

signal miss
signal hit(hit_obj)

func _ready():
	._ready()
	$PumpTimer.connect("timeout", self, "did_not_hit")
	add_to_group("pumps")

func launch(dir : Vector2, level : LevelHandler):
	LEVEL = level
	travel_dir = dir

func _process(delta):
	position += travel_dir * SPEED * delta
	
	if not LEVEL.is_tile_dug(position):
		did_not_hit()

func did_not_hit():
	emit_signal("miss")
	destroy_self()

func _on_Pump_area_entered(area):
	emit_signal("hit", area)
	destroy_self()
