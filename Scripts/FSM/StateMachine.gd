class_name StateMachine extends Node

@export var initial_state: State
var current_state: State

func _ready():
	if initial_state:
		change_state(initial_state)

func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func change_state(new_state: State):
	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()
