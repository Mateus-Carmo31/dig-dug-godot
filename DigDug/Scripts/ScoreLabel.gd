extends Node2D

func set_score(score : int):
	$Label.text = str(score)

func _ready():
	$Timer.start()

func _on_Timer_timeout():
	queue_free()
