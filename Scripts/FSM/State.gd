class_name State
extends Node

## Abstract Base Class for the Finite State Machine (FSM).
## Acts as an interface that all concrete states (e.g., PlayingState, MenuState) must inherit from.
## Defines the standard lifecycle methods: Enter, Exit, Update, and PhysicsUpdate.

# Reference to the StateMachine that owns this state.
var state_machine = null

# Reference to the entity controlled by this state (e.g., the Player node or the Board).
var context = null 

## Virtual function called once when the state becomes active.
## Use this for initialization (e.g., starting animations, resetting timers).
func enter():
	pass

## Virtual function called once when the state is about to be replaced.
## Use this for cleanup (e.g., stopping sounds, disconnecting signals).
func exit():
	pass 

## Virtual function called every frame (process loop).
## Use this for logic that runs continuously (e.g., input detection, timers).
## @param _delta: Time elapsed since the last frame.
func update(_delta: float):
	pass 

## Virtual function called every physics frame (physics_process loop).
## Use this for rigid body movement or collision checks.
## @param _delta: Fixed time elapsed since the last physics frame.
func physics_update(_delta: float):
	pass
