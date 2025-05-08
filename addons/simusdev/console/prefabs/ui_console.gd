extends CanvasLayer

@onready var console: SD_TrunkConsole = SimusDev.console

@export var line_edit: LineEdit

@export var _container: Control
@export var _tips: Control

func _ready() -> void:
	console.on_update.connect(_on_update)
	
	console.update_console()
	
	
	_tips.initialize(console)


func _on_update() -> void:
	var buffer: Array[SD_ConsoleMessage] = console.get_messages_from_buffer()
	while buffer.size() > 0:
		
		var msg: SD_ConsoleMessage = buffer[0]
		_container.init_message(msg)
		console.erase_message_from_buffer(msg)
	

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_string: String = event.as_text_key_label().to_lower()
		if event.is_pressed():
			match key_string:
				"quoteleft":
					if console.disable_console_on_release and SD_Platforms.is_release_build():
						return
						
					if SD_Platforms.is_debug_build() or SD_Platforms.is_pc():
						visible = !visible
						
				"enter":
					if visible:
						console.try_execute(line_edit.text)
						line_edit.text = ""
						_tips.clear_tips()
						line_edit.grab_focus()
						line_edit.grab_click_focus()
						


func _on_sd_node_input_on_input(event: InputEvent) -> void:
	pass

func _on_draw() -> void:
	await get_tree().create_timer(0.1, true, true).timeout
	line_edit.grab_click_focus()
	line_edit.grab_focus()
	_tips.update_tips()
	


func _on_enter_text_changed(new_text: String) -> void:
	_tips.update_tips(new_text)

func _on_ui_console_tips_tip_selected(cmd: SD_ConsoleCommand) -> void:
	line_edit.text = ""
	var new_text: String = "%s %s" % [cmd.get_code(), cmd.get_value_as_string()]
	line_edit.insert_text_at_caret(new_text)


func _on_sd_node_console_commands_on_executed(command: SD_ConsoleCommand) -> void:
	match command.get_code():
		"cmd.list":
			console.print_all_commands()
		"console.clear":
			clear()
		"clear":
			clear()
		"console.hide":
			hide()
		"console.show":
			show()

func clear() -> void:
	console.clear_message_buffer()
	_container.clear_messages()
	_on_update()

func _on_visibility_changed() -> void:
	if console:
		console.visibility_changed.emit()
		if visible:
			_on_draw()
