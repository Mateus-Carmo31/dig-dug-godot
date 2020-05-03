extends GridEntity

# Current problems:
# AI will break if completely surrounded
# No transition between states

const DIRS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
enum {AIMLESS, FOLLOW, PUMPED, GHOST}

export(float) var move_speed : float = 48
export(float) var ghost_speed : float = 48
export(int, 5, 10) var change_state_counter : int = 5
export(int, 200, 1000, 100) var kill_score : int = 200

var last_valid_pos : Vector2
var target_pos : Vector2
var state = FOLLOW
var current_dir = Vector2.RIGHT

onready var count : float = change_state_counter
onready var cur_pump : int = 0
onready var anim_tree = $AnimationTree
onready var anim_state = anim_tree.get("parameters/playback")

signal pump_release
signal enemy_died(pos, kill_score, killed_by_rock)

func _ready():
	._ready()
	
	add_to_group("enemies")
	
	position = position.snapped(GRID)
	last_valid_pos = position
	target_pos = position
	
	anim_tree.active = true
	print("Enemy ready!")
	
	if GameHandler.debug_mode:
		$DebugLabel.show()

func _process(delta):
	match(state):
		
		AIMLESS:
			aimless_state(delta)
		FOLLOW:
			follow_state(delta)
		GHOST:
			ghost_state(delta)
		PUMPED:
			pumped_state(delta)
	
	if GameHandler.debug_mode:
		debug_state()
		update()

# ----------- AIMLESS STATE -----------------

func aimless_state(delta):
	# Check if direction is valid (empty tile / no obstacle)
	#   If it is, set direction and target
	#   If not, get valid directions and choose one randomly
	
	if position == target_pos:
		last_valid_pos = position
		if not can_move_towards(current_dir):
			current_dir = pick_valid_dir(0.5)
		
		anim_tree.set("parameters/Walk/blend_position", current_dir.x)
		anim_tree.set("parameters/Hurt/blend_position", current_dir.x)
		target_pos = last_valid_pos + current_dir * GRID
	
	position += move_speed * current_dir * delta
	
	if position.distance_to(target_pos) <= move_speed * delta:
		position = target_pos
	
	if count > 0:
		count -= delta
	else:
		count = change_state_counter
		change_to_state(FOLLOW)


# Picks a random valid direction from the currently valid ones
# If the picked one would go back the same way, reroll according to
# chance_of_same w/o the way-back direction. 
# This gives the AI less chance of picking the same direction.
func pick_valid_dir(chance_of_same : float):
	randomize()
	
	var dirs = get_valid_dirs()
	var can_choose_same = (randf() <= chance_of_same)
	
	var new_dir = dirs[randi() % dirs.size()]
	
	if new_dir == current_dir * -1 and dirs.size() > 1:
		if not can_choose_same:
			dirs.erase(new_dir)
			new_dir = dirs[randi() % dirs.size()]
	
	return new_dir

# ----------- FOLLOW STATE --------------------

func follow_state(delta):
	
	if position == target_pos:
		last_valid_pos = position
		if not can_move_towards(current_dir) or at_intersection():
			current_dir = find_destination_dir()
			anim_tree.set("parameters/Walk/blend_position", current_dir.x)
			anim_tree.set("parameters/Hurt/blend_position", current_dir.x)
		
		target_pos = last_valid_pos + current_dir * GRID
	
	position += move_speed * current_dir * delta
	
	if position.distance_to(target_pos) <= move_speed * delta:
		position = target_pos
	
	if count > 0:
		count -= delta
	else:
		var dest_pos : Vector2
		
		dest_pos = LEVEL.last_player_pos
		
		if position.distance_squared_to(dest_pos) <= 25600:
			count = change_state_counter/2
			change_to_state(AIMLESS)
		else:
			count = change_state_counter/2
			anim_state.travel("Ghost")
			$CollisionShape2D.disabled = true
			change_to_state(GHOST)

# Checks all valid directions, then finds the one that would lead the closest
# to the destination. If no direction takes to a position closer to the destination
# than the current position (preferred_dir was not changed), then returns a random
# valid direction.
# Also, the direction leading back the previous path (current_dir * -1) is removed
# from the valid ones, in all cases except when it is the only one available
# (deadends, with valid_dirs.size() == 1). This avoids jittery movement.
func find_destination_dir():
	randomize()
	
	var valid_dirs = get_valid_dirs()
	var dest_pos : Vector2 = LEVEL.last_player_pos
	
	if valid_dirs.size() > 1:
		valid_dirs.erase(current_dir * -1)
	
	var preferred_dir : Vector2 = Vector2.ZERO
	var best_dist := position.distance_squared_to(dest_pos)
	
	for dir in valid_dirs:
		
		var new_pos : Vector2 = position + dir * GRID
		var new_dist = new_pos.distance_squared_to(dest_pos)
		
		if new_dist < best_dist:
			best_dist = new_dist
			preferred_dir = dir
	
	if preferred_dir != Vector2.ZERO:
		return preferred_dir
	else:
		return valid_dirs[randi() % valid_dirs.size()]

# ----------- GHOST STATE ---------------------

func ghost_state(delta):
	
	if count > 0:
		target_pos = LEVEL.last_player_pos.snapped(GRID)
		count -= delta
	
	var travel_dir := (target_pos - position).normalized()
	
	position = position + travel_dir * ghost_speed * delta
	
	if position.distance_to(target_pos) <= ghost_speed * delta:
		position = target_pos
	
	if position == target_pos:
		last_valid_pos = position
		target_pos = position
		count = change_state_counter
		anim_state.travel("Walk")
		$CollisionShape2D.disabled = false
		change_to_state(FOLLOW)

# -------------- PUMPED STATE ------------------------

# Uses count to gradually reduce the enemy's pump. If the enemy is pumped
# by the player, the count restarts. If the count reaches 0, the enemy loses
# one point of pump. If cur_pump reaches 0, the enemy moves normally again.
# If cur_pump reaches 4, the enemy dies.
func pumped_state(delta):
	
	if count > 0:
		count -= delta
	else:
		count = change_state_counter/2
		cur_pump -= 1
	
	if cur_pump == 0:
		emit_signal("pump_release")
		get_released()
	elif cur_pump == 4:
		emit_signal("pump_release")
		kill_enemy()

# Called by the player on the enemy. Never called by the enemy itself.
func get_pumped():
	if state != PUMPED:
		state = PUMPED
		count = change_state_counter/2
		cur_pump = 1
		anim_state.travel("Hurt")
	else:
		cur_pump += 1
	
	$PumpSFX.play()

func get_released():
	cur_pump = 0
	state = FOLLOW
	anim_state.travel("Walk")

# ----------- UTILITY -------------------------

# Checks if tile is valid for the enemy
func is_valid_tile(tile):
	
	if not LEVEL.is_in_bounds(tile):
		return false
	
	if not LEVEL.is_tile_dug(tile):
		return false
	
	if LEVEL.has_obstacle_at(tile):
		return false
	
	return true

# Checks if the enemy can move towards this direction
func can_move_towards(dir):
	var tile = last_valid_pos + dir * GRID
	return is_valid_tile(tile)

# Returns directions enemy can walk towards
func get_valid_dirs():
	var valid_dirs = []
	for dir in DIRS:
		if can_move_towards(dir):
			valid_dirs.append(dir)
	
	return valid_dirs

func at_intersection():
	if get_valid_dirs().size() >= 3:
#		print("At intersection!")
		return true
	else:
		return false

func change_to_state(_state):
	state = _state

func kill_enemy(was_killed_by_rock = false):
	# Emit death signal
	emit_signal("enemy_died", position, kill_score, was_killed_by_rock)
	# Destroy Enemy
	destroy_self()
	# Return score for utility purposes
	return kill_score

func reset_position():
	.reset_position()
	
	last_valid_pos = position
	target_pos = position
	anim_state.travel("Walk")
	state = FOLLOW
	$CollisionShape2D.disabled = false

func _draw():
	draw_circle(target_pos - position + Vector2(16,16), 4, Color.white)
	draw_circle(last_valid_pos - position + Vector2(16,16), 4, Color.blue)

func debug_state():	
	match(state):
		AIMLESS:
			$DebugLabel.text = "Aimless"
		FOLLOW:
			$DebugLabel.text = "Follow"
		GHOST:
			$DebugLabel.text = "Ghost"
		PUMPED:
			$DebugLabel.text = "%.2f %s" % [count, cur_pump]


