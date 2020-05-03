extends Control

func _ready():
	
	for child in get_children():
		if child.has_method("hide"):
			child.hide()

func start_display(score):
	$YouWin.visible = true
	$SFXPlayer.play()
	yield(get_tree().create_timer(1.0), "timeout")
	
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
	
	$RestartButton.visible = true
	$ReturnButton.visible = true
	$SFXPlayer.play()
	
	$RestartButton.grab_focus()

func _on_RestartButton_pressed():
	get_tree().change_scene("res://Scenes/MainScene.tscn")

func _on_ReturnButton_pressed():
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
