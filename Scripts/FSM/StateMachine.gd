class_name StateMachine
extends Node

## Generic Finite State Machine (FSM) Controller.
## Manages the lifecycle of active states and handles transitions between them.
## This component delegates the '_process' and '_physics_process' calls to the currently active state.

# The starting state of the machine (set via the Inspector).
@export var initial_state: State

# The state currently running the logic. Only one state can be active at a time.
var current_state: State

func _ready():
	# Initialize the machine with the default state if one is assigned.
	if initial_state:
		change_state(initial_state)

## Game Loop Delegation.
## Passes the frame delta to the active state's update logic.
func _process(delta):
	if current_state:
		current_state.update(delta)

## Physics Loop Delegation.
## Passes the physics delta to the active state's physics logic.
func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

## Handles the transition from the old state to the new state.
## 1. Calls 'exit()' on the current state (cleanup).
## 2. Updates the reference to the new state.
## 3. Calls 'enter()' on the new state (initialization).
func change_state(new_state: State):
	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()
