extends Control

signal close_menu

func _ready():
	load_settings()
	for option in $Options.get_children():
		option.connect("focus_entered", self, "_enable_selected_effect", [option])
		option.connect("focus_exited", self, "_disable_selected_effect", [option])

func _input(event):
	if visible and event.is_action("ui_cancel"):
		save_settings()
		hide()
		emit_signal("close_menu")
		accept_event()

func activate_options():
	show()
	$Options/MasterOption.grab_focus()

# Shader-based blinking effect
func _enable_selected_effect(option):
	print("Here for: ", option.name, "!")
	var mat : Material = option.get_child(0).get_material()
	if mat != null:
		mat.set_shader_param("blink_enabled", true)

func _disable_selected_effect(option):
	var mat : Material = option.get_child(0).get_material()
	if mat != null:
		mat.set_shader_param("blink_enabled", false)

# Saves all settings that can be serialized
# Right now, just the volume settings
func save_settings():
	var settings_file = File.new()
	settings_file.open("user://settings.data", File.WRITE)
	
	for option in $Options.get_children():
		if option.has_method("serialize"):
			settings_file.store_line(to_json(option.serialize()))

func load_settings():
	var settings_file = File.new()
	
	if not settings_file.file_exists("user://settings.data"):
		return
	
	settings_file.open("user://settings.data", File.READ)
	for option in $Options.get_children():
		if option.has_method("deserialize"):
			var data = parse_json(settings_file.get_line())
			option.deserialize(data)
