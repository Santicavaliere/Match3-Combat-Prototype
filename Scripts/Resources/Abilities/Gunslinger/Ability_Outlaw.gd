extends Ability
class_name Ability_Outlaw

# CORRECCIÓN: Ahora encadena ID 3 (Bombas).
func execute(combat_manager: Node):
	var grid = combat_manager.grid_manager
	if grid:
		var count = 0
		for x in grid.width:
			for y in grid.height:
				# ID 3 = BOMBAS
				if grid.grid_data[x][y] == 3: 
					var piece = grid._get_piece_at(x, y)
					if piece:
						piece.set_locked(true)
						count += 1
		
		print("Outlaw: ", count, " bombs have been chained.")
