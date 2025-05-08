extends CharacterBody3D
class_name WorldPlayer

@export_group("References")
@export var camera_controller: W_FPControllerCamera
@export var movement_controller: W_FPControllerMovement
@export var character_component: W_ComponentCharacterBody3D
@export var health_component: C_HealthComponent
@export var head: Node3D

@export var _animation_player: AnimationPlayer

@export var _character_sync: SD_MultiplayerSynchronizer

static var instance: WorldPlayer = null

static var _players: Array[WorldPlayer] = []

var _multiplayer_player: SD_MultiplayerPlayer

func get_multiplayer_player() -> SD_MultiplayerPlayer:
	return _multiplayer_player

static func get_player_list() -> Array[WorldPlayer]:
	return _players

func _exit_tree() -> void:
	if is_multiplayer_authority():
		instance = null
	
	_players.erase(self)
	EventBus.on_player_despawned.emit(self)

func _ready() -> void:
	if is_multiplayer_authority():
		instance = self
	_players.append(self)
	
	camera_controller.enabled = is_multiplayer_authority()
	character_component.enabled = is_multiplayer_authority()
	movement_controller.enabled = is_multiplayer_authority()
	
	head.visible = !is_multiplayer_authority()
	camera_controller.current = is_multiplayer_authority()
	
	
	EventBus.on_player_spawned.emit(self)

func _physics_process(delta: float) -> void:
	
	var is_sprinting: bool = _character_sync.get_synced_data().get("is_sprinting", character_component.is_sprinting)
	var _veloctiy: Vector3 = character_component.get_velocity()
	var animation_to_play: String = "idle"
	
	var move_dir: Vector3 = _character_sync.get_synced_data().get("move_direction", character_component.get_move_direction())
	
	if move_dir:
		animation_to_play = "walk"
		if is_sprinting:
			animation_to_play = "run"
		

	_animation_player.play(animation_to_play)

func is_playable() -> bool:
	return is_multiplayer_authority()

func _on_w_fp_controller_camera_mouse_motion(event: InputEventMouseMotion, relative: Vector2) -> void:
	head.rotation_degrees.x = clamp(head.rotation_degrees.x - relative.y * 0.5, -90, 90)
