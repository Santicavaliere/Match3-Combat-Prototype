extends Ability
class_name Ability_Kraken

## KRAKEN'S ABILITY IMPLEMENTATION
##
## Specific logic for the Pirate class ability (Kraken's Talisman).
## Effect: Summons minions (Tentacles) that perform passive attacks on every match.

## Executes the Kraken's skill logic (Tentacles of the Abyss).
##
## Mechanics:
## 1. Clears any existing minions from the CombatManager to prevent stacking issues.
## 2. Initializes the `active_tentacles` array with 4 new entities.
## 3. Each tentacle is assigned 5 HP (represented as integers in the array).
##
## @param combat_manager: Reference to the main combat controller to access the minion list.
func execute(combat_manager: Node):
	# Clear previous tentacles for safety
	combat_manager.active_tentacles.clear()
	
	# Summon 4 tentacles with 5 HP each
	combat_manager.active_tentacles = [5, 5, 5, 5]
	
	print("Kraken: 4 Tentacles summoned! They will attack on every match.")
