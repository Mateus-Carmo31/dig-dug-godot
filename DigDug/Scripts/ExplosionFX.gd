extends Particles2D

func explode(is_rock_kill):
	if not is_rock_kill:
		$ExplosionSFX.stream = RESOURCES.PUMP_EXPLOSION_SFX
	else:
		$ExplosionSFX.stream = RESOURCES.ROCK_EXPLOSION_SFX
	
	$ExplosionSFX.play()
	restart()
	$Timer.start()
	
func _on_Timer_timeout():
	queue_free()
