extends Ability
class_name Ability_Looter

## LOOTER'S ABILITY IMPLEMENTATION
##
## Specific logic for the Explorer class ability (Looter's Talisman).
## Effect: Steals a percentage of the enemy's current gold reserves.

## Executes the Looter's skill logic.
##
## Mechanics:
## 1. Calculates 30% of the enemy's total gold.
## 2. Deducts that amount from the enemy and adds it to the player.
## 3. Logs the transaction to the console.
##
## @param combat_manager: Reference to the main combat controller to access gold variables.
func execute(combat_manager: Node):
	# Calculate 30%
	var steal_amount = int(combat_manager.enemy_gold * 0.30)
	
	# Transfer
	combat_manager.enemy_gold -= steal_amount
	combat_manager.player_gold += steal_amount
	
	print("Looter: Stole ", steal_amount, " gold coins!")
	# Future TODO: Emit a signal here to update the Gold UI
