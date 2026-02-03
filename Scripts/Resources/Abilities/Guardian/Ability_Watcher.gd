extends Ability
class_name Ability_Watcher

## WATCHER'S ABILITY IMPLEMENTATION
##
## Specific logic for the Guardian class ability (Watcher's Talisman).
## Effect: Silences the enemy, preventing them from using magic or special abilities in the upcoming turn.

## Executes the Watcher's skill logic (Protective Eye).
##
## Mechanics:
## 1. Accesses the `is_enemy_magic_blocked` flag in the CombatManager.
## 2. Sets it to TRUE. The Enemy AI (in CombatManager) must check this flag before queuing abilities.
## 3. Logs the status effect to the console.
##
## @param combat_manager: Reference to the main combat controller to access state flags.
func execute(combat_manager: Node):
	combat_manager.is_enemy_magic_blocked = true
	print("Watcher: Enemy magic blocked for the next turn.")
