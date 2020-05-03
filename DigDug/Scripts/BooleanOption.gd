extends HBoxContainer

export(String) var param

func _ready():
	$Button.pressed = GameHandler.get(param)
	$Button.connect("toggled", self, "_on_Button_toggled")

func _gui_input(event):
	if event.is_action_pressed("ui_accept"):
		toggle_option()

func toggle_option():
	$Button.pressed = not $Button.pressed

func _on_Button_toggled(button_pressed):
	GameHandler.set(param, button_pressed)
	$SFXPlayer.play()
	print("GameHandler's \"", param, "\" parameter set to ", GameHandler.get(param))

func _on_Button_focus_entered():
	grab_focus()
