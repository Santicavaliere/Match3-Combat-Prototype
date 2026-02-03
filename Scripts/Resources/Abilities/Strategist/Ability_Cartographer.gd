extends Ability
class_name Ability_Cartographer

## CARTOGRAPHER'S ABILITY IMPLEMENTATION
##
## Specific logic for the Strategist class ability (Cartographer).
## Effect: Steals Blue pieces (Scrolls) from the board. 
## Future implementation: Converts collected scrolls into immediate Experience Points (XP).

## Executes the Cartographer's skill logic (Scroll Theft).
##
## Mechanics:
## 1. Accesses the Match-3 Grid via the CombatManager.
## 2. Targets and collects (destroys) up to 5 Blue pieces (ID 1 - Scrolls).
## 3. Prints the result to the console.
## Note: XP generation logic is currently commented out as a all item.
##
## @param combat_manager: Reference to the main combat controller to access the Grid.
func execute(combat_manager: Node):
	var grid = combat_manager.grid_manager
	if grid:
		# ID 1 es AZUL (Pergaminos)
		var stolen = grid.collect_random_pieces(1, 5)
		print("Cartógrafo: Se robaron ", stolen, " pergaminos.")
		# Note: The PDF says it provides XP. Since there's no XP system yet,
		# I'm commenting EVERYTHING here.
		# SignalBus.xp_gained.emit(stolen * 10)
