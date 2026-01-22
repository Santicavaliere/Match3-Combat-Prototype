extends Node

## Global Game Manager.
## Controls the high-level flow of the application using a simple Finite State Machine (FSM).
## This script is intended to be used as an Autoload (Singleton) to be accessible globally.

## Enum defining the possible states of the game loop.
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

# Stores the current active state. Defaults to MENU.
var current_state = GameState.MENU

## Updates the game state to 'new_state'.
## This function acts as the central hub for state transitions, useful for 
## triggering side effects (like pausing the scene tree or switching UI panels).
func change_state(new_state):
	current_state = new_state
	print("Game State Changed to: ", new_state)
