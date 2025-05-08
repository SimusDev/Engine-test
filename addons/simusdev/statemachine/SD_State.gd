@icon("res://addons/simusdev/icons/Groups.svg")
extends Node
class_name SD_State

@export var id: String

var _state_machine: SD_NodeStateMachine

signal transitioned()

static func create(state_id: String) -> SD_State:
	var state := SD_State.new()
	state.id = state_id
	return state

func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update(delta: float) -> void:
	pass

func _physics_update(delta: float) -> void:
	pass
