extends Control

func _ready():
	$YouWin.visible = false
	$FinalScoreText.visible = false
	$FinalScore.visible = false
	$Thanks.visible = false
	$Source.visible = false

func start_display(score, lives):
	$YouWin.visible = true
	$MusicPlayer.play()
	yield($MusicPlayer, "finished")
	yield(get_tree().create_timer(0.5), "timeout")
	
	$FinalScoreText.visible = true
	$SFXPlayer.play()
	yield(get_tree().create_timer(1.0), "timeout")
	
	$FinalScore.text = str(score)
	$FinalScore.visible = true
	
	if score > GameHandler.high_score:
		$NewHighScore.visible = true
		GameHandler.set_new_high_score(score)
	
	$SFXPlayer.play()
	yield(get_tree().create_timer(1.0), "timeout")
	
	$Thanks.visible = true
	$Source.visible = true
	$SFXPlayer.play()
	yield(get_tree().create_timer(4.0), "timeout")
	
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
