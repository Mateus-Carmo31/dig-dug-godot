extends HBoxContainer

enum Buses {Master, Music, SFX}
export(Buses) var bus_id

func _ready():
	match_bar_to_audio()

func _gui_input(event):
	if event.is_action_pressed("ui_right"):
		increase_volume()
	elif event.is_action_pressed("ui_left"):
		decrease_volume()

func increase_volume():
	get_child(1).value += get_child(1).step
	match_audio_to_bar()

func decrease_volume():
	get_child(1).value -= get_child(1).step
	match_audio_to_bar()

func serialize():
	var serialized = {
		"bus_name" : AudioServer.get_bus_name(bus_id),
		"bus_volume" : db2linear(AudioServer.get_bus_volume_db(bus_id))
	}
	return serialized

func deserialize(data):
	get_child(1).value = data["bus_volume"]
	AudioServer.set_bus_volume_db(bus_id, linear2db(data["bus_volume"]))
	match_bar_to_audio()

func match_audio_to_bar():
	AudioServer.set_bus_volume_db(bus_id, linear2db(get_child(1).value))
	print(AudioServer.get_bus_name(bus_id), " bus value is now ", linear2db(get_child(1).value), " dB!")
	$SampleAudio.play()

func match_bar_to_audio():
	get_child(1).value = db2linear(AudioServer.get_bus_volume_db(bus_id))
