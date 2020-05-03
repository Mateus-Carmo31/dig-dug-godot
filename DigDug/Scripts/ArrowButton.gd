extends Button

func _ready():
	$TextureRect.visible = false

func _on_ArrowButton_focus_entered():
	$TextureRect.visible = true

func _on_ArrowButton_focus_exited():
	$TextureRect.visible = false
