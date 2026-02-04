extends Ability
class_name Ability_Bastion

# CORRECCIÓN: Ahora busca ID 3 (Bombas), no ID 0.
func execute(combat_manager: Node):
	var grid = combat_manager.grid_manager
	if grid:
		# ID 3 = BOMBAS (Antes era 0)
		var destroyed_count = grid.collect_random_pieces(3, 3)
		
		if destroyed_count > 0:
			var heal_percent = 0.03 * destroyed_count
			var heal_amount = int(combat_manager.MAX_HP * heal_percent)
			
			combat_manager.player_hp += heal_amount
			if combat_manager.player_hp > combat_manager.MAX_HP:
				combat_manager.player_hp = combat_manager.MAX_HP
			
			combat_manager.update_ui_text()
			print("Bastión: Healed ", heal_amount, " HP (", destroyed_count, " bombs absorbed).")
		else:
			print("Bastion: No bombs available.")
