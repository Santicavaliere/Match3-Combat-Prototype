extends Node

## Global Event Bus (Singleton).
## Implements the Observer Pattern to decouple game systems.
## Allows independent components (Grid, UI, Combat) to communicate without direct references.
## This script must be configured as an Autoload in Project Settings.

## Emitted when the GridManager finishes generating the initial board.
## Useful for triggering entry animations or starting the game timer.
signal grid_generated

## Emitted when a valid match is processed and destroyed.
## Carries the tile type ID (gem_type) and the count of tiles matched (amount).
signal match_found(gem_type: int, amount: int)

# --- NEW SIGNALS ---

## Emitted whenever the number of remaining moves changes.
## Used to update the UI counter.
signal moves_updated(moves_left: int)

## Emitted when the player's turn is completely over.
## (After all cascades, refilling, and animations have finished).
signal turn_ended

## Emitted when the enemy completes their entire phase (3 actions).
## Signals the GridManager to reset the player's moves.
signal enemy_turn_finished 

## Signal intended for visual feedback when the enemy takes damage.
## Can be used to trigger screen shake or particle effects.
signal enemy_damaged(amount: int)

## Signal intended for healing mechanics (e.g. matching Green tiles).
signal player_healed(amount: int)

## Emitted when a victory or defeat condition is met.
## 'player_won' is true if the player won (Enemy HP = 0), false if lost (Player HP = 0).
signal game_over(player_won: bool)

# Eliminamos la señal anterior de 'current, max'
# Usamos un diccionario para enviar todos los manás de una vez
signal mana_updated(mana_dict: Dictionary)

# --- NUEVAS SEÑALES PARA UI FINAL ---
signal player_hp_changed(current_hp: int, max_hp: int)
signal enemy_hp_changed(current_hp: int, max_hp: int)
# Ya tienes mana_updated y moves_updated, esas las usaremos tal cual.
