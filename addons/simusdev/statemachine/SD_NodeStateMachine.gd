@icon("res://addons/simusdev/icons/GroupViewport.svg")
extends Node
class_name SD_NodeStateMachine

@export var initial_state: SD_State

var states := {}
var current_state: SD_State

static func find(node: Node) -> SD_NodeStateMachine:
	return node.get_meta("SD_NodeStateMachine", null)

func _ready() -> void:
	for child in get_children():
		if child is SD_State:
			states[child.name] = child
			child._state_machine = self
			child.transitioned.connect(_on_state_transitioned.bind(child))
	
	if initial_state:
		current_state = initial_state
		current_state._enter()
	
	
	

func add_state(state: SD_State) -> void:
	if states.has(state):
		return
	
	state._state_machine = self
	state.transitioned.connect(_on_state_transitioned.bind(state))

func remove_state(state: SD_State) -> void:
	if not states.has(state):
		return
	
	state.transitioned.disconnect(_on_state_transitioned)

func _on_state_transitioned(from: SD_State, to: SD_State) -> void:
	if from != current_state:
		return
	
	if !to:
		return
	
	if current_state:
		current_state._exit()
	
	current_state = to
	to._enter()
	

func _process(delta: float) -> void:
	if current_state:
		current_state._update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state._physics_update(delta)
