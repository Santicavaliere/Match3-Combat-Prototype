extends Ability
class_name Ability_Corsair

## CORSAIR'S ABILITY IMPLEMENTATION
##
## Specific logic for the Pirate class ability (Corsair's Justice / Ghost Bottle).
## Effect: Equalizes the health of both the player and the enemy to the average of their current values.

## Executes the Corsair's skill logic (Health Equalization).
##
## Mechanics:
## 1. Retrieves the current HP of both the Player and the Enemy.
## 2. Calculates the integer average of the two values.
## 3. Sets both the Player's and Enemy's HP to this calculated average.
## 4. Updates the UI immediately to reflect the sudden change in health bars.
##
## @param combat_manager: Reference to the main combat controller to access and modify HP values.
func execute(combat_manager: Node):
	var p_hp = combat_manager.player_hp
	var e_hp = combat_manager.enemy_hp
	
	
	var average = int((p_hp + e_hp) / 2)
	
	
	combat_manager.player_hp = average
	combat_manager.enemy_hp = average
	
	combat_manager.update_ui_text()
	print("Corsair: Divine justice. Lives equal to ", average)
