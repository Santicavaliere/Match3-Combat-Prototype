extends Ability
class_name Ability_Archivist

## ARCHIVIST'S ABILITY IMPLEMENTATION
##
## Specific logic for the Strategist class ability (Archivist).
## Effect: Deals massive damage based on a percentage of the enemy's current health.

## Executes the Archivist's skill logic (Ancient Cannon).
##
## Mechanics:
## 1. Calculates damage equal to 25% of the Enemy's CURRENT HP.
## 2. Ensures a minimum of 1 damage is always dealt.
## 3. Applies the calculated damage via the CombatManager.
##
## @param combat_manager: Reference to the main combat controller to access enemy_hp.
func execute(combat_manager: Node):
	var current_hp = combat_manager.enemy_hp
	var damage = int(current_hp * 0.25)
	
	if damage < 1: damage = 1
	
	combat_manager.apply_damage_to_enemy(damage)
	print("Archivista: Daño masivo de ", damage)
