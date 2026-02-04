extends Ability
class_name Ability_Navigator

# CORRECCIÓN: Ahora convierte a ID 6 (Pergaminos).
func execute(combat_manager: Node):
	var grid = combat_manager.grid_manager
	if grid:
		# ID 6 = PERGAMINOS
		grid.convert_random_pieces_to(6, 4)
		print("Navigator: Created 4 Scrolls on the board.")
