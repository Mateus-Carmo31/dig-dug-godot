extends Node
class_name GameStateHandler

var lives : int = 2
var score : int = 0
var enemy_count : int = 0

var current_level : int = 0

var can_pause = true

signal game_over(final_score)
signal game_finished(final_score, lives_left)

func _ready():
	print("GSH Started!")
	connect("game_over", GameHandler, "game_over")
	connect("game_finished", GameHandler, "game_finished")
	
	$HUDLayer/HUD/HighScore.text = str(GameHandler.high_score)
	update_round()
	update_scoreboard()
	
	change_to_level(0)

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		pause_game()

func change_to_level(level_id : int):
	
	print("Changing to level ", level_id, "!")
	
	# Queue old level for deletion
	var old_level = get_node_or_null("GameArea")
	if old_level != null:
		old_level.queue_free()
	
	# Wait for deletion
	yield(get_tree(), "idle_frame")
	
	# Instance new level
	add_child(RESOURCES.LEVELS[level_id].instance())
	
	# Connect level signals
	get_node("GameArea").connect("dug_tile", self, "add_to_score", [10])
	
	# Connect player signals
	var new_player = get_node("GameArea/Player")
	new_player.connect("player_died", self, "on_Player_death")
	
	# Connect enemies signals
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy_count += 1
		enemy.connect("enemy_died", self, "on_Enemy_death")
	
	# Update level display
	update_round()
	
	ready_player_pause(4.09 if level_id == 0 else 2.0)

func on_Player_death():
	
	can_pause = false
	
	# Subtract life
	lives -= 1
	$HUDLayer/HUD/LivesBar.value = lives
	
	if lives >= 0:
		print("Current lives: ", lives)
		
		# Reposition player/enemies
		for entity in get_tree().get_nodes_in_group("grid_entities"):
			if (entity as Node).is_in_group("obstacles"):
				if entity.is_waiting() == false:
					entity.break_state()
				else:
					entity.reset_to_wait()
			else:
				entity.reset_position()
		
		# Remove stray pumps
		get_tree().call_group("pumps", "queue_free")
		
		# Reactivate player
		get_node("GameArea/Player").reactivate()
		
		# Unpause game
		get_tree().paused = false
		
		can_pause = true
	else:
		print("Game Over!")
		$HUDLayer/HUD/GameOverText.visible = true
		get_node("GameArea").clean_up_map()
		
		$MusicStream.play()
		yield($MusicStream, "finished")
		get_tree().paused = false
		emit_signal("game_over", score)

func on_Enemy_death(pos, kill_score, rock_kill):
	enemy_count -= 1
	
	# Gives points to score. Double if rock kill!
	score += kill_score * 2 if rock_kill else kill_score
	
	# Caps score at 999_999
	if score > 999999:
		score = 999999
	
	update_scoreboard()
	
	if enemy_count == 0:
		
		current_level += 1
		
		if current_level < RESOURCES.LEVELS.size():
			get_tree().paused = true
			can_pause = false
			
			print("Start change timer!")
			$MusicStream.play()
			yield($MusicStream, "finished")
			yield(get_tree().create_timer(0.5), "timeout")
			
			change_to_level(current_level)
			get_tree().paused = false
		else:
			get_tree().paused = true
			print("Game finished!")
			$MusicStream.play()
			yield($MusicStream, "finished")
			yield(get_tree().create_timer(0.5), "timeout")
			get_tree().paused = false
			emit_signal("game_finished", score, lives)

func add_to_score(points : int):
	score += points
	if score > 999999:
		score = 999999
	
	update_scoreboard()

func pause_game():
	
	var player = get_node_or_null("GameArea/Player")
	var player_dead = player.state == Player.DEAD if player != null else false
	
	if can_pause and not player_dead:
		
		get_tree().paused = !get_tree().paused
		
		if get_tree().paused == true:
			$HUDLayer/PauseSFX.play()
		$HUDLayer/HUD/PausedText.visible = get_tree().paused

func update_round():
	$HUDLayer/HUD/Round.text = str(current_level+1)

func update_scoreboard():
	$HUDLayer/HUD/Score.text = str(score) if score > 0 else "00"

func ready_player_pause(wait_in_seconds : float):
	can_pause = false
	get_tree().paused = true
	$HUDLayer/HUD/ReadyText.visible = true
	yield(get_tree().create_timer(wait_in_seconds), "timeout")
	$HUDLayer/HUD/ReadyText.visible = false
	get_tree().paused = false
	can_pause = true

func _on_MusicStream_finished():
	if $MusicStream.stream != RESOURCES.GAME_OVER_SFX:
		$MusicStream.stream = RESOURCES.GAME_OVER_SFX
