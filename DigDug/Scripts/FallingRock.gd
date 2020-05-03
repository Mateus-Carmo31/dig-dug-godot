extends GridEntity

enum {WAIT, FALLING, BREAK, TRANSITION}
var state := WAIT

export(float) var fall_speed = 64

var running_score : int = 0
onready var anim_player := $AnimationPlayer

signal rock_fallen(pos, total_score)

func _ready():
	._ready()
	
	if is_inside_tree():
		add_to_group("obstacles")
	print("Rock ready!")

# WIP: Rock Logic
func _process(delta):

	match(state):
		WAIT:
			wait_state()
		FALLING:
			falling_state(delta)
		BREAK:
			break_state()

func wait_state():
	var is_underneath_free = LEVEL.is_tile_dug(position + Vector2.DOWN * GRID)
	var player_underneath = LEVEL.last_player_pos == position + Vector2.DOWN * GRID
	if is_underneath_free and not player_underneath:
		change_to_state(TRANSITION)
		anim_player.play("PrepareAndFall")

func falling_state(delta):
	var fall_pos := position + Vector2.DOWN * GRID
	if (LEVEL.is_tile_dug(fall_pos) and not LEVEL.has_obstacle_at(fall_pos)
	and LEVEL.is_in_bounds(fall_pos)):
		position += Vector2.DOWN * fall_speed * delta
	else:
		if is_in_group("obstacles"):
			remove_from_group("obstacles") # Make rock traversable
		
		pause_mode = PAUSE_MODE_PROCESS
		change_to_state(TRANSITION)
		anim_player.play("Break")

func break_state():
	emit_signal("rock_fallen", position, running_score)
	destroy_self()

func is_waiting():
	return state == WAIT

func change_to_state(_state):
	state = _state

func _on_Rock_area_entered(area):
	if state == FALLING:
		if area.get_collision_layer_bit(0): # Checks if is in "player" layer
			area.kill_player()
		elif area.get_collision_layer_bit(1): # Checks if is in "enemies" layer
			var kill_score = area.kill_enemy(true)
			running_score += kill_score * 2

func reset_to_wait():
	anim_player.stop()
	reset_position()
