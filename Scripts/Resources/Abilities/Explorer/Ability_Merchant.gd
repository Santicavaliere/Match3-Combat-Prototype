extends Ability
class_name Ability_Merchant

## MERCHANT'S ABILITY IMPLEMENTATION
##
## Specific logic for the Explorer class ability (Merchant's Talisman).
## Effect: Reduces the enemy's evasion stat and increases the player's evasion (Player evasion logic is currently a placeholder).

## Executes the Merchant's skill logic.
##
## Mechanics:
## 1. Reduces `enemy_evasion` by 0.30 (30%).
## 2. Clamps the value to ensure evasion doesn't drop below 0.
## 3. Logs the action (Note: Player evasion increase is pending implementation of the `player_evasion` variable).
##
## @param combat_manager: Reference to the main combat controller to access evasion stats.
func execute(combat_manager: Node):
	# Reduce enemy evasion
	combat_manager.enemy_evasion -= 0.30
	if combat_manager.enemy_evasion < 0: combat_manager.enemy_evasion = 0
	
	# Note: We don't have a 'player_evasion' variable yet, but the log is ready.
	print("Merchant: Enemy evasion lowered. Your evasion increased (Logic pending).")
