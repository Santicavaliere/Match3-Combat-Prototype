extends Ability
class_name Ability_Duelist

## DUELIST'S ABILITY IMPLEMENTATION
##
## Specific logic for the Gunslinger class ability (Duelist / High Velocity Bullet).
## Effect: Deals distinct damage based on a percentage of the enemy's current health.

## Executes the Duelist's skill logic.
##
## Mechanics:
## 1. Calculates damage equal to 30% of the Enemy's CURRENT HP.
## 2. Ensures a minimum of 1 damage is always dealt (clamping).
## 3. Applies the calculated damage via the CombatManager.
##
## @param combat_manager: Reference to the main combat controller to access enemy_hp.
func execute(combat_manager: Node):
	var current_hp = combat_manager.enemy_hp
	var dmg = int(current_hp * 0.30)
	
	if dmg < 1: dmg = 1
	
	combat_manager.apply_damage_to_enemy(dmg)
	print("Duelist: Sharp shot for ", dmg, " damage.")
