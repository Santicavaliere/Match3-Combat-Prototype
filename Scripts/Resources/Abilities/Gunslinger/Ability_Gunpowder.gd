extends Ability
class_name Ability_Gunpowder

# CORRECCIÓN: Ahora detona ID 3 (Bombas).
func execute(combat_manager: Node):
	var grid = combat_manager.grid_manager
	if grid:
		# ID 3 = BOMBAS
		var destroyed = grid.collect_random_pieces(3, 4)
		print("Gunpowder: Barrel exploded. ", destroyed, " bombs detonated.")
