extends Ability
class_name Ability_Outlaw

## OUTLAW'S ABILITY IMPLEMENTATION
##
## Specific logic for the Gunslinger class ability (Outlaw's Talisman).
## Effect: "Chains" all Red Bombs on the board, preventing them from being moved or falling.

## Executes the Outlaw's skill logic (Chained Pistol).
##
## Mechanics:
## 1. Iterates through the entire grid coordinate system.
## 2. Identifies all pieces with ID 0 (Red Bombs).
## 3. Calls set_locked(true) on the specific Piece nodes, disabling their input and physics.
## 4. Counts and logs the number of affected pieces.
##
## @param combat_manager: Reference to the main combat controller to access the Grid.
func execute(combat_manager: Node):
	var grid = combat_manager.grid_manager
	if grid:
		var count = 0
		# Iterate through the entire board looking for Bombs (ID 0)
		for x in grid.width:
			for y in grid.height:
				if grid.grid_data[x][y] == 0: # If it is a Red Bomb
					var piece = grid._get_piece_at(x, y)
					if piece:
						piece.set_locked(true)
						count += 1
		
		print("Outlaw: ", count, " bombs have been chained.")
