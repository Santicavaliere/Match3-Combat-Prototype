extends Ability
class_name Ability_Bastion

## BASTION'S ABILITY IMPLEMENTATION
##
## Specific logic for the Guardian class ability (Bastion).
## Effect: Destroys specific pieces on the board to regenerate health.

## Executes the Bastion's skill logic (Matter Absorption).
##
## Mechanics:
## 1. Targets and destroys up to 3 Red pieces (ID 0 - Bombs) from the Grid.
## 2. Calculates healing amount: 3% of MAX HP for each piece destroyed.
## 3. Heals the player, clamping the value to ensure it doesn't exceed MAX HP.
##
## @param combat_manager: Reference to the main combat controller to access the Grid and Player HP.
func execute(combat_manager: Node):
	var grid = combat_manager.grid_manager
	if grid:
		var destroyed_count = grid.collect_random_pieces(0, 3)
		
		
		if destroyed_count > 0:
			var heal_percent = 0.03 * destroyed_count
			var heal_amount = int(combat_manager.MAX_HP * heal_percent)
			
			
			combat_manager.player_hp += heal_amount
			if combat_manager.player_hp > combat_manager.MAX_HP:
				combat_manager.player_hp = combat_manager.MAX_HP
			
			combat_manager.update_ui_text()
			print("Bastión: Healed ", heal_amount, " HP (", destroyed_count, " red pieces destroyed).")
		else:
			print("Bastion: There were no red pieces for absorption.")
