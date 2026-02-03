extends Ability
class_name Ability_TreasureHunter

## TREASURE HUNTER ABILITY IMPLEMENTATION
##
## Specific logic for the Explorer class ability (Treasure Hunter).
## Effect: Grants the player additional moves (effectively extra turns) immediately.

## Executes the Treasure Hunter skill logic.
##
## Mechanics:
## 1. Accesses the GridManager via the CombatManager.
## 2. Interprets "2 Extra Turns" as movement points.
##    (Standard conversion: 1 Turn = 3 Moves, therefore 2 Turns = +6 Moves).
## 3. Adds 6 moves to the current counter and updates the UI via the SignalBus.
##
## @param combat_manager: Reference to the main combat controller to access the Grid.
func execute(combat_manager: Node):
	
	var grid = combat_manager.grid_manager
	if grid:
		grid.current_moves += 6
		SignalBus.moves_updated.emit(grid.current_moves)
		print("Treasure Hunter: You gained 6 extra moves!")
