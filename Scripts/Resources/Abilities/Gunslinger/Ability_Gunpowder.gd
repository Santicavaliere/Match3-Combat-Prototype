extends Ability
class_name Ability_Gunpowder

## GUNPOWDER ABILITY IMPLEMENTATION
##
## Specific logic for the Gunslinger class ability (Gunpowder Talisman).
## Effect: Targeted destruction of Red pieces (Bombs) on the board.

## Executes the Gunpowder skill logic.
##
## Mechanics:
## 1. Accesses the Match-3 Grid via the CombatManager.
## 2. Targets and destroys up to 4 Red pieces (ID 0 - Bombs).
## 3. Prints the execution result to the console.
##
## @param combat_manager: Reference to the main combat controller to access the Grid.
func execute(combat_manager: Node):
	var grid = combat_manager.grid_manager
	if grid:
		# ID 0 = Red (Bombs)
		var destroyed = grid.collect_random_pieces(0, 4)
		print("Gunpowder: Barrel exploded. ", destroyed, " bombs detonated.")
