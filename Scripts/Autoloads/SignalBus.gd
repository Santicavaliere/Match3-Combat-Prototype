extends Node

## Global Event Bus (Singleton).
## Implements the Observer Pattern to decouple game systems.
## Allows independent components (Grid, UI, Combat) to communicate without direct references.
## This script must be configured as an Autoload in Project Settings.

# --- BOARD & TURN SIGNALS ---

## Emitted when the GridManager finishes generating the initial board.
## Useful for triggering entry animations or starting the game timer.
signal grid_generated

## Emitted when a valid match is processed and destroyed.
## Carries the tile type ID (gem_type) and the count of tiles matched (amount).
signal match_found(gem_type: int, amount: int)

## Emitted whenever the number of remaining moves changes.
## Used to update the UI counter.
signal moves_updated(moves_left: int)

## Emitted when the player's turn is completely over.
## (After all cascades, refilling, and animations have finished).
signal turn_ended

## Emitted when the enemy completes their entire phase (3 actions).
## Signals the GridManager to reset the player's moves.
signal enemy_turn_finished 

# --- COMBAT & STATS SIGNALS ---

## Emitted when the enemy takes actual damage.
## Can be used to trigger screen shake or particle effects.
signal enemy_damaged(amount: int)

## Emitted when the player takes actual damage (after evasion and shields calculation).
signal player_damaged(amount: int)

## Signal intended for healing mechanics (e.g., matching Green tiles).
signal player_healed(amount: int)

## Emitted when a victory or defeat condition is met.
## 'player_won' is true if the player won (Enemy HP = 0), false if lost (Player HP = 0).
signal game_over(player_won: bool)

# --- UI STATE SIGNALS ---

## Emitted when the player's mana pool changes.
## Carries a dictionary containing the current amounts for all mana colors.
signal mana_updated(mana_dict: Dictionary)

signal enemy_mana_updated(mana_dict: Dictionary)

## Emitted when the player's health points change.
signal player_hp_changed(current_hp: int, max_hp: int)

## Emitted when the enemy's health points change.
signal enemy_hp_changed(current_hp: int, max_hp: int)

## Emitted when the player's evasion stat changes.
signal player_evasion_changed(current_evasion: float)

## Emitted when the enemy's evasion stat changes.
signal enemy_evasion_changed(current_evasion: float)

## Emitted when the player collects gold.
signal player_gold_changed(new_amount: int)

## Emitted when the player collects experience points.
signal player_xp_changed(new_amount: int)

## Emitted when the enemy collects gold.
signal enemy_gold_changed(new_amount: int)

## Emitted when the enemy collects experience points.
signal enemy_xp_changed(new_amount: int)

# --- ABILITY SIGNALS ---

## Emitted when the player clicks on a magic ability from the scroll.
signal ability_cast_requested(ability: Ability)

## Emitted when a magic ability is successfully executed (mana requirements met).
signal ability_cast_success(ability: Ability)

# --- AI & ANIMATION SYNCHRONIZATION ---


## Emitted by the visual enemy ship at the exact moment of impact to apply damage.
signal apply_damage_to_player(amount: int)

## Emitted by the visual enemy ship to signal that its action and animations are complete.
signal enemy_animation_finished


signal enemy_attack_requested(damage_amount: int, is_miss: bool, bomb_count: int)

signal player_attack_requested(damage_amount: int, is_miss: bool, bomb_count: int)

signal helm_match_animation
signal enemy_helm_match_animation
signal evasion_consumed(is_player_target: bool, amount: float)

# --- LIFE SYSTEM SIGNALS ---
signal life_system_updated(current_lives: int, time_left_seconds: int)

signal poseidon_fragments_changed(new_amount: int)
signal show_lives_purchase_popup # Para cuando se quede en 0

## Emitted when a piece is destroyed, requesting the Magic Dust VFX.
## Carries the start position and the tile type ID.
signal vfx_magic_dust_requested(start_pos: Vector2, piece_type: int, is_enemy: bool)
