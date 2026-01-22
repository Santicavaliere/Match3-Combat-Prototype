extends Node

# Estado global simple
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }
var current_state = GameState.MENU

func change_state(new_state):
	current_state = new_state
	print("Game State Changed to: ", new_state)
	# Aquí podrías emitir una señal o pausar el árbol de escenas
