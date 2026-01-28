extends Node

## Global Event Bus (Singleton).
## Implements the Observer Pattern to decouple game systems.
## Allows independent components (Grid, UI, Combat) to communicate without direct references.
## This script must be configured as an Autoload in Project Settings.

## Emitted when the GridManager finishes generating the initial board.
## Useful for triggering entry animations or starting the game timer.
signal grid_generated

signal match_found(gem_type: int, amount: int)  # <--- ¡ESTA ES LA QUE DA ERROR!

# --- NUEVA SEÑAL ---
## Se emite cada vez que cambia la cantidad de movimientos restantes.
signal moves_updated(moves_left: int)

## Emitted when the player's turn is completely over.
## (After all cascades, refilling, and animations have finished).
signal turn_ended

## Signal intended for visual feedback when the enemy takes damage.
## Can be used to trigger screen shake or particle effects.
signal enemy_damaged(amount: int)

## Signal intended for healing mechanics (e.g. matching Green tiles).
signal player_healed(amount: int)
