extends Node
class_name SD_AdsCoreYandex

signal rewarded_ad(result: String)
signal interstitial_ad(result: String)
signal player_initialized()
signal leaderboard_initialized()
signal data_loaded(data)
signal leaderboard_player_entry_loaded(data)
signal leaderboard_entries_loaded(data)
signal stats_loaded(stats: Dictionary)
signal check_auth(answer: bool)

var is_game_ready : bool = false
var is_player_initialized : bool = false
var is_leaderboard_initialized: bool = false

var is_game_initialization_started: bool = false
var is_player_initialization_started: bool = false
var is_leaderboard_initialization_started: bool = false

var is_authorized: bool = false

var callback_player_initialized = JavaScriptBridge.create_callback(_player_initialized)
var callback_leaderboard_initialized = JavaScriptBridge.create_callback(_leaderboard_initialized)

var callback_rewarded_ad = JavaScriptBridge.create_callback(_rewarded_ad)
var callback_ad = JavaScriptBridge.create_callback(_interstitial_ad)
var callback_is_authorized = JavaScriptBridge.create_callback(_is_authorized)

var callback_data_loaded = JavaScriptBridge.create_callback(_data_loaded)
var callback_stats_loaded = JavaScriptBridge.create_callback(_stats_loaded)
var callback_leaderboard_player_entry_loaded = JavaScriptBridge.create_callback(_leaderboard_player_entry_loaded)
var callback_leaderboard_entries_loaded = JavaScriptBridge.create_callback(_leaderboard_entries_loaded)

@onready var window = JavaScriptBridge.get_interface("window")

func is_working() -> bool:
	return true

func open_auth_dialog() -> void:
	if not is_player_initialized:
		init_player()
		await player_initialized
	if not is_authorized:
		window.OpenAuthDialog()

func check_is_authorized() -> void:
	if not is_player_initialized:
		init_player()
		await player_initialized
	if not is_authorized:
		window.CheckAuth(callback_is_authorized)

func _is_authorized(answer) -> void:
	is_authorized = answer[0]
	check_auth.emit(is_authorized)

func init_leaderboard() -> void:
	if not is_leaderboard_initialization_started:
		is_leaderboard_initialization_started = true
		window.InitLeaderboard(callback_leaderboard_initialized)

func game_ready() -> void:
	if not is_game_ready:
		is_game_ready = true
		window.GameReady()

# Analytics
func gameplay_started() -> void:
	window.GameplayStarted()

func gameplay_stopped() -> void:
	window.GameplayStopped()

func show_interstitial_ad() -> void:
	window.ShowAd(callback_ad)

func show_rewarded_ad() -> void:
	window.ShowAdRewardedVideo(callback_rewarded_ad)

func init_player() -> void:
	if is_player_initialization_started:
		return
	is_player_initialization_started = true
	window.InitPlayer(false, callback_player_initialized)


func save_data(data: Dictionary, flush: bool = false) -> void:
	if not is_player_initialized:
		init_player()
		await player_initialized
	var saves = JavaScriptBridge.create_object("Object")
	for i in data.keys():
		if data[i] is int:
			saves[i] = float(data[i])
		else:
			saves[i] = data[i]
	window.SaveData(saves, flush)


func save_stats(stats: Dictionary) -> void:
	if not is_player_initialized:
		init_player()
		await player_initialized
	var saves = JavaScriptBridge.create_object("Object")
	for i in stats.keys():
		saves[i] = float(stats[i])
	window.SaveStats(saves)


func increment_stats(increments: Dictionary) -> void:
	if not is_player_initialized:
		init_player()
		await player_initialized
	var saves = JavaScriptBridge.create_object("Object")
	for i in increments.keys():
		saves[i] = increments[i]
	window.incrementStats(saves, callback_stats_loaded)


func save_leaderboard_score(leaderboard_name, score, extra_data="") -> void:
	if not is_leaderboard_initialized:
		await leaderboard_initialized
	window.SaveLeaderboardScore(leaderboard_name, score, extra_data)


func load_all_data() -> void:
	if not is_player_initialized:
		init_player()
		await player_initialized
	window.loadAllData(callback_data_loaded)


func load_data(keys: Array) -> void:
	if not is_player_initialized:
		init_player()
		await player_initialized
	var saves = JavaScriptBridge.create_object("Array", keys.size())
	for i in range(keys.size()):
		saves[i] = keys[i]
	window.LoadData(saves, callback_data_loaded)


func load_all_stats() -> void:
	if not is_player_initialized:
		init_player()
		await player_initialized
	window.loadAllStats(callback_stats_loaded)


func load_stats(keys: Array) -> void:
	if not is_player_initialized:
		init_player()
		await player_initialized
	var saves = JavaScriptBridge.create_object("Array", keys.size())
	for i in range(keys.size()):
		saves[i] = keys[i]
	window.LoadStats(saves, callback_stats_loaded)


func load_leaderboard_player_entry(leaderboard_name: String) -> void:
	if not is_leaderboard_initialized:
		await leaderboard_initialized
	window.LoadLeaderboardPlayerEntry(leaderboard_name, callback_leaderboard_player_entry_loaded)


func load_leaderboard_entries(leaderboard_name: String, include_user: bool, quantity_around: int, quantity_top: int) -> void:
	if not is_leaderboard_initialized:
		await leaderboard_initialized
	window.LoadLeaderboardEntries(leaderboard_name, include_user, quantity_around, quantity_top, callback_leaderboard_entries_loaded)


func _rewarded_ad(args) -> void:
	rewarded_ad.emit(args[0])


func _interstitial_ad(args) -> void:
	interstitial_ad.emit(args[0])


func _data_loaded(args) -> void:
	var result := {}
	var keys = JavaScriptBridge.get_interface("Object").keys(args[0])
	var values = JavaScriptBridge.get_interface("Object").values(args[0])
	for i in range(keys.length):
		result[keys[i]] = values[i]
	data_loaded.emit(result)


func _stats_loaded(args) -> void:
	var result := {}
	var keys = JavaScriptBridge.get_interface("Object").keys(args[0])
	var values = JavaScriptBridge.get_interface("Object").values(args[0])
	for i in range(keys.length):
		result[keys[i]] = values[i]
	stats_loaded.emit(result)


func _leaderboard_player_entry_loaded(args) -> void:
	if args[0] == 'loaded':
		var result := {}
		var keys = JavaScriptBridge.get_interface("Object").keys(args[1])
		var values = JavaScriptBridge.get_interface("Object").values(args[1])
		for i in range(keys.length):
			result[keys[i]] = values[i]
		leaderboard_player_entry_loaded.emit(result)


func _leaderboard_entries_loaded(args) -> void:
	if args[0] == 'loaded':
		var result := {}
		var keys = JavaScriptBridge.get_interface("Object").keys(args[1])
		var values = JavaScriptBridge.get_interface("Object").values(args[1])
		for i in range(keys.length):
			result[keys[i]] = values[i]
		leaderboard_entries_loaded.emit(result)
	elif args[0] == 'error':
		print("Произошла ошибка при загрузке лидерборда.")

func _player_initialized(args) -> void:
	is_player_initialized = true
	player_initialized.emit()


func _leaderboard_initialized(args) -> void:
	is_leaderboard_initialized = true
	leaderboard_initialized.emit()
