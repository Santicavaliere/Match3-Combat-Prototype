extends Ability
class_name Ability_Navigator

## NAVIGATOR'S ABILITY IMPLEMENTATION
##
## Specific logic for the Strategist class ability (Navigator's Route).
## Effect: Transmutes random pieces on the board into Blue pieces (Scrolls).

## Executes the Navigator's skill logic.
##
## Mechanics:
## 1. Accesses the Match-3 Grid via the CombatManager.
## 2. Calls the grid utility to convert 4 random non-blue pieces into Blue pieces (ID 1).
##
## @param combat_manager: Reference to the main combat controller to access the Grid.
func execute(combat_manager: Node):
	var grid = combat_manager.grid_manager
	if grid:
		# Converts 4 random pieces to ID 1 (Blue)
		grid.convert_random_pieces_to(1, 4)
