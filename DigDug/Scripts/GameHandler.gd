extends Node

var debug_mode : bool = false
var high_score : int

func _ready():
	high_score = retrieve_high_score()
	print("GameHandler ready!")

func game_over(final_score):
	get_tree().change_scene("res://Scenes/GameOverScreen.tscn")
	yield(get_tree(), "idle_frame")
	get_tree().current_scene.start_display(final_score)

func game_finished(final_score, lives):
	get_tree().change_scene("res://Scenes/ResultsScreen.tscn")
	yield(get_tree(), "idle_frame")
	get_tree().current_scene.start_display(final_score, lives)

func retrieve_high_score() -> int:
	var score_storage : File = File.new()
	
	if not score_storage.file_exists("user://high_score.data"):
		score_storage.open("user://high_score.data", File.WRITE)
		score_storage.store_32(10000)
		return 10000
	else:
		score_storage.open("user://high_score.data", File.READ)
		return score_storage.get_16()

func set_new_high_score(score : int):
	var score_storage : File = File.new()
	
	score_storage.open("user://high_score.data", File.WRITE)
	score_storage.store_32(score)
	high_score = score
