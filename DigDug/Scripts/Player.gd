extends GridEntity
class_name Player

export(float) var move_speed = 48

onready var anim_tree = $AnimationTree
onready var anim_state = anim_tree.get("parameters/playback")

enum {MOVING, LAUNCH, PUMPING, DEAD}

var state = MOVING
var is_moving := false
var last_valid_pos : Vector2
var target_pos : Vector2
var current_move_dir := Vector2.ZERO
var last_recorded_dir := Vector2.ZERO # Used by pump. Couldn't find a better method

var enemy_in_pump = null
var can_pump = true

signal dug_at_position(pos)
signal player_died

func _ready():
	._ready()
	
	position = position.snapped(GRID)
	last_valid_pos = position
	target_pos = position
	
	anim_tree.active = true
	
	print("Player Ready!")

func _process(delta):
	
	if (state != DEAD and state != LAUNCH and state != PUMPING and 
	Input.is_action_just_pressed("player_action")):
		state = LAUNCH
		$PlayerSFX.play()
		launch_pump()
		anim_state.travel("Launch")
	
	match(state):
		MOVING:
			movement(delta)
		PUMPING:
			pump()
	
	if GameHandler.debug_mode:
		update()

func movement(delta):
	
	if position.distance_to(target_pos) <= move_speed * delta:
		position = target_pos
	
	# SNAP
	if position == target_pos:
		last_valid_pos = position
		emit_signal("dug_at_position", last_valid_pos)
		current_move_dir = validate_dir(get_new_move_dir())
		if current_move_dir != Vector2.ZERO:
			last_recorded_dir = current_move_dir
		target_pos += current_move_dir * GRID
	
	# MOVEMENT
	# Checks if the player wants to move
	# If the new direction is opposite to the current one,
	#  changes the movement to be opposite to the current one and updates
	#  current_dir (also swapping last_valid_pos and target_pos)
	# If not, just moves the player normally
	#
	# This is my attempt at replicating DigDug's grid-like movement, where 
	# the player can move between cells but is always aligned for certain
	# movements.
	if get_new_move_dir() != Vector2.ZERO:
		anim_state.travel("Digging")
		if get_new_move_dir() == current_move_dir * -1:
			var temp : Vector2 = target_pos
			target_pos = last_valid_pos
			last_valid_pos = temp
			current_move_dir = current_move_dir * -1
			set_anim_state_directions(current_move_dir)
		else:
			position += move_speed * current_move_dir * delta
	else:
		anim_state.travel("IdleDig")

# Checks if moving in some direction would hit an obstacle
# Also change the Animation Tree's state in the case of a valid dir
func validate_dir(dir : Vector2):
	if is_target_blocked(dir):
		dir = Vector2.ZERO
	
	if dir != Vector2.ZERO:
		set_anim_state_directions(dir)
		start_music()
	
	return dir

# ---------------------------------------------

# PUMPING STATE
# If the player moves, release the pump.
# Else, if the player hit an enemy, can pump and presses the key, prompt the
# enemy to get pumped by one point. See @WalkerEnemy.gd and @Pump.gd
func pump():
	if get_new_move_dir() != Vector2.ZERO:
		state = MOVING
		release_pump()
		anim_state.travel("Launch")
	
	if enemy_in_pump != null and can_pump and Input.is_action_just_pressed("player_action"):
		anim_state.start(anim_state.get_current_node())
		enemy_in_pump.get_pumped()
		can_pump = false
		$PumpTimer.start()

# Creates a pump that will inform the player if it hits anything using signals.
func launch_pump():
	var new_pump = RESOURCES.PUMP.instance()
	new_pump.connect("hit", self, "on_pump_hit")
	new_pump.connect("miss", self, "on_pump_miss")
	
	new_pump.position = position + Vector2(16,16)
	get_parent().add_child(new_pump)
	new_pump.launch(current_move_dir if current_move_dir != Vector2.ZERO 
	else last_recorded_dir, LEVEL)

# Connects enemy to player in case of pump hit
func on_pump_hit(hit_obj):
	enemy_in_pump = hit_obj
	hit_obj.connect("pump_release", self, "release_pump")
	hit_obj.get_pumped()
	state = PUMPING
	anim_state.travel("Pump")

func on_pump_miss():
	state = MOVING

# Disconnects the enemy from the player
func release_pump():
	if enemy_in_pump != null:
		enemy_in_pump.disconnect("pump_release", self, "release_pump")
	enemy_in_pump = null
	state = MOVING

# A timer for stopping the player from spamming to kill enemies
func _on_PumpTimer_timeout():
	can_pump = true

# ---------------------------------------------
# Gets a new move direction from input
func get_new_move_dir():
	var dir := Vector2()
	
	var LEFT = Input.is_action_pressed("move_left")
	var RIGHT = Input.is_action_pressed("move_right")
	var UP = Input.is_action_pressed("move_up")
	var DOWN = Input.is_action_pressed("move_down")
	
	dir.x = -int(LEFT) + int(RIGHT)
	dir.y = -int(UP) + int(DOWN)
	
	if dir.x != 0 and dir.y != 0:
		dir.x = 0 # Vertical priority (in case of diagonal input)
	
	return dir

func is_target_blocked(dir : Vector2):
	
	var next_pos = last_valid_pos + dir * GRID
	
	if not LEVEL.is_in_bounds(next_pos):
		return true
	
	if LEVEL.has_obstacle_at(next_pos):
		return true
	
	return false

func start_music():
	if not $MelodyStream.playing:
		var bass_time = $BassStream.get_playback_position()
		$MelodyStream.play(bass_time)
		$MusicTimer.start()
	else:
		$MusicTimer.start()

func _on_MusicTimer_timeout():
	stop_music()

func stop_music():
	$MelodyStream.stop()

func set_anim_state_directions(dir):
	anim_tree.set("parameters/Digging/blend_position", dir)
	anim_tree.set("parameters/IdleDig/blend_position", dir)
	anim_tree.set("parameters/DeadAnim/blend_position", dir)
	anim_tree.set("parameters/Launch/blend_position", dir)
	anim_tree.set("parameters/Pump/blend_position", dir)

func kill_player():
	# Releases enemy
	release_pump()
	# Pause game
	pause_mode = PAUSE_MODE_PROCESS
	get_tree().paused = true
	# Stop movement
	state = DEAD
	# [8-bit music stops]
	$MelodyStream.stop()
	$BassStream.stop()
	# Play death animation and sound effect
	# DeathAnim also signals player death!
	$PlayerSFX.stop()
	$PlayerSFX.stream = RESOURCES.PLAYER_DEATH_SFX
	$PlayerSFX.play()
	anim_state.travel("DeadAnim")

func reset_position():
	.reset_position()
	
	last_valid_pos = position
	target_pos = position

func reactivate():
	reset_position()
	pause_mode = PAUSE_MODE_INHERIT
	anim_state.travel("IdleDig")
	$Sprite.visible = true
	$BassStream.play()
	$PlayerSFX.stop()
	$PlayerSFX.stream = RESOURCES.PUMP_LAUNCH_SFX
	state = MOVING

func _on_Player_area_entered(area):
	if area.get_collision_layer_bit(1):
		kill_player()

func _draw():
	if GameHandler.debug_mode:
		draw_circle(target_pos - position + Vector2(16,16), 4, Color.red)
		draw_circle(last_valid_pos - position + Vector2(16,16), 4, Color.green)
