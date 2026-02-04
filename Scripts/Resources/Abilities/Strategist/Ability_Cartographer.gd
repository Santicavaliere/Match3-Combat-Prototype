extends Ability
class_name Ability_Cartographer

# CORRECCIÓN: Ahora roba ID 6 (Pergaminos/Scrolls).
func execute(combat_manager: Node):
	var grid = combat_manager.grid_manager
	if grid:
		# ID 6 = PERGAMINOS (Scrolls)
		var stolen = grid.collect_random_pieces(6, 5)
		print("Cartógrafo: Se robaron ", stolen, " pergaminos.")
		
		# Opcional: Si quieres que robe XP inmediatamente
		# combat_manager.player_xp += (stolen * 100)
