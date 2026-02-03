extends Resource
class_name Ability

## BASE CLASS FOR ABILITIES (TEMPLATE)
##
## This script serves as the blueprint for all active skills in the game.
## Concrete abilities (e.g., Ability_Kraken, Ability_Outlaw) must inherit from this class.
## It defines the data structure for the Inspector and the virtual execution method.


@export_group("Identity")
@export var ability_name: String = "Skill Name"
@export_multiline var description: String = "Skill Description"
@export var icon: Texture2D

@export_group("Costs")
@export var cost_red: int = 0
@export var cost_blue: int = 0
@export var cost_green: int = 0
@export var cost_yellow: int = 0



## Virtual Function: Executes the ability's logic.
##
## This method is intended to be OVERRIDDEN by child classes.
## The base implementation prints a debug message but performs no action.
##
## @param combat_manager: A reference to the active CombatManager node. 
## This allows the ability to access the Grid, Player HP, Enemy HP, and Game State.
func execute(combat_manager: Node):
	print("Base ability executed (No logic implemented).")
