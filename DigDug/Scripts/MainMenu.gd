extends Control

func _ready():
	$Menu/HighScore.text = str(GameHandler.high_score)
	$Menu/Start.grab_focus()
	$OptionsMenu.connect("close_menu", self, "close_options")

func _on_Start_pressed():
	get_tree().change_scene("res://Scenes/MainScene.tscn")

func _on_Options_pressed():
	open_options()

func _on_Quit_pressed():
	get_tree().quit()

func open_options():
	$Menu.hide()
	$OptionsMenu.activate_options()

func close_options():
	$Menu.show()
	$Menu/Start.grab_focus()
