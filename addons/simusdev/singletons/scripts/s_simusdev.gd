extends Node

const VERSION: String = "BETA 4.0"

signal on_notification(what: int)

var canvas := SD_TrunkCanvas.new()
var console := SD_TrunkConsole.new()
var eventbus := SD_TrunkEventBus.new()
var localization := SD_TrunkLocalization.new()
var keybinds := SD_TrunkKeybinds.new()
var modloader := SD_TrunkModLoader.new()

var window := SD_TrunkWindow.new()
var audio := SD_TrunkAudio.new()

var db_resource := SD_DBResource.new()

var gamesaver := SD_GameSaver.new()

var game := SD_TrunkGame.new()
var monetization := SD_TrunkMonetization.new()

var tools := SD_TrunkTools.new()

signal process(delta: float)
signal physics_process(delta: float)

var _autoload_classes = [
	SD_Random.new(),
	SD_Platforms.new(),
	SD_FileSystem.new(),
	SD_FileExtensions.new(),
	SD_ResourceLoader.new(),
	SD_Array.new(),
	SD_Config.new(),
	SD_ConfigEncrypted.new(),
	SD_ConsoleCategories.new(),
	SD_Console.new(),
	SD_ConsoleMessage.new(),
	SD_Settings.new(),
	SD_BooleansStorage.new(),
]

func _ready() -> void:
	canvas._ready()
	console._ready()
	eventbus._ready()
	localization._ready()
	window._ready()
	audio._ready()
	
	keybinds._ready()
	var _s_keybinds := SD_Binds.new(keybinds)
	
	modloader._ready()
	
	
	game._ready()
	monetization._ready()
	var _s_monetization := SD_Monetization.new(monetization)
	
	tools._ready()
	
	_initialize_commands()
	
	write_engine_info()

func _initialize_commands() -> void:
	console.on_command_executed.connect(_on_command_executed)
	console.create_commands_by_list(["quit", "engine.quit", "engine.version", "engine.info"])

func _on_command_executed(cmd: SD_ConsoleCommand) -> void:
	match cmd.get_unique_code():
		"engine.quit":
			quit()
		"quit":
			quit()
		"engine.info":
			write_engine_info()
		"engine.version":
			write_engine_info()

func write_engine_info() -> void:
	var info: String = "SimusEngine: Version: %s" % [str(SimusDev.VERSION)]
	console.write_info(info)

func _process(delta: float) -> void:
	process.emit(delta)
	
	modloader._process(delta)

func _physics_process(delta: float) -> void:
	physics_process.emit(delta)
	
	modloader._physics_process(delta)


func quit(exit_code: int = 0) -> void:
	get_tree().quit(exit_code)

func _notification(what: int) -> void:
	on_notification.emit(what)
