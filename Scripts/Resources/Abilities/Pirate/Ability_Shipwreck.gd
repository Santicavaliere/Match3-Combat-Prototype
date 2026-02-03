extends Ability
class_name Ability_Shipwreck

## SHIPWRECK ABILITY IMPLEMENTATION
##
## Specific logic for the Pirate class ability (Shipwreck).
## Effect: Strikes the enemy with lightning, dealing damage equal to a percentage of their current health.

## Executes the Shipwreck skill logic (Electric Tentacle/Lightning).
##
## Mechanics:
## 1. Retrieves the Enemy's CURRENT HP.
## 2. Calculates damage equal to 35% of that current value.
## 3. Enforces a minimum of 1 damage unit.
## 4. Applies the damage and logs the event.
##
## @param combat_manager: Reference to the main combat controller to access enemy_hp.
func execute(combat_manager: Node):
	# Calculate 35% of CURRENT health
	var current_hp = combat_manager.enemy_hp
	var dmg = int(current_hp * 0.35)
	
	# Always deal at least 1 damage
	if dmg < 1: dmg = 1
	
	combat_manager.apply_damage_to_enemy(dmg)
	print("Shipwreck: Electric lightning causes ", dmg, " damage.")
