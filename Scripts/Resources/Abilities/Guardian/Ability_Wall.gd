extends Ability
class_name Ability_Wall

## WALL'S ABILITY IMPLEMENTATION
##
## Specific logic for the Guardian class ability (Wall's Talisman).
## Effect: Creates a complete shield that negates the next incoming damage instance (100% reduction).

## Executes the Wall's skill logic (Stone Wall).
##
## Mechanics:
## 1. Sets the `damage_reduction_next_hit` variable in CombatManager to 1.0 (representing 100%).
## 2. The CombatManager will check this value before applying the next enemy attack, reducing it to 0.
## 3. Logs the shield activation to the console.
##
## @param combat_manager: Reference to the main combat controller to access defense variables.
func execute(combat_manager: Node):
	# 100% reduction (1.0) for the next hit
	combat_manager.damage_reduction_next_hit = 1.0
	print("Wall: Shield activated. Next damage will be 0.")
