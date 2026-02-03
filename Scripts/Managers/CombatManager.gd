extends Control

class_name CombatManager

## CORE COMBAT CONTROLLER
##
## Manages the central loop of the game, including:
## 1. Turn State Machine (Player vs. Enemy).
## 2. HP & Resource Tracking (Health, Gold, Colored Mana).
## 3. Damage Logic (Calculations, Shields, Win/Loss conditions).
## 4. Ability Execution & Validation.
## 5. Communication between the Match-3 Grid and the RPG layer.

# --- UI REFERENCES (Ensure paths are correct) ---
@onready var moves_label = $MovesLabel
# Adjust these paths if you placed labels inside containers
@onready var player_hp_label = $DebugPanel/VBoxContainer/PlayerHPLabel
@onready var enemy_hp_label = $DebugPanel/VBoxContainer/EnemyHPLabel
@onready var turn_label = $DebugPanel/VBoxContainer/TurnLabel

# --- EXTERNAL REFERENCES ---
# IMPORTANT! Drag the GridManager node here in the Godot Inspector
@export var grid_manager: GridManager

# --- CONFIGURATION (PDF RULES) ---
const MAX_HP = 50 

const DMG_MATCH_3 = 3
const DMG_MATCH_4 = 5
const DMG_MATCH_5 = 8

# --- CONFIGURATION ---
const MAX_MANA_PER_COLOR = 50 # Cap for individual mana colors

# --- GAME STATE ---

## Stores the current mana for all 4 colors.
## Keys: "red", "blue", "green", "yellow".
var mana_pool = {
	"red": 0,
	"blue": 0,
	"green": 0,
	"yellow": 0
}
var player_hp: int = MAX_HP
var enemy_hp: int = MAX_HP
var is_player_turn: bool = true
var enemy_gold: int = 1000 # Simulated enemy gold
var player_gold: int = 0
var enemy_evasion: float = 0.0 # Percentage 0.0 to 1.0
var damage_reduction_next_hit: float = 0.0 # Percentage 0.0 to 1.0 (Shields)
var is_enemy_magic_blocked: bool = false   # If true, enemy cannot use skills
var active_tentacles: Array = [] # List of HP for active Kraken minions (e.g. [5, 5])

## Initialization of UI and Signal connections.
func _ready():
	# Initialize UI
	update_ui_text()
	_update_mana_ui() # Update UI at start
	
	# Connect Signals
	SignalBus.match_found.connect(_on_match_made)
	SignalBus.moves_updated.connect(_on_moves_updated)
	# NEW SECURE CONNECTION: Waits for cascades to finish before changing turns
	SignalBus.turn_ended.connect(_on_player_turn_ended_safely)

# --- MANA SYSTEM (COLORED) ---

## Adds mana to a specific pool based on tile color.
## Clamps the value to MAX_MANA_PER_COLOR.
## @param color_type: "red", "blue", "green", or "yellow".
## @param amount: The quantity to add.
func add_mana(color_type: String, amount: int):
	if color_type in mana_pool:
		mana_pool[color_type] += amount
		# Clamp (Cap)
		if mana_pool[color_type] > MAX_MANA_PER_COLOR:
			mana_pool[color_type] = MAX_MANA_PER_COLOR
			
		_update_mana_ui()

## Validates if the player possesses the required mana cost.
## Returns True only if ALL color requirements are met.
func has_enough_mana(c_red: int, c_blue: int, c_green: int, c_yellow: int) -> bool:
	if mana_pool["red"] < c_red: return false
	if mana_pool["blue"] < c_blue: return false
	if mana_pool["green"] < c_green: return false
	if mana_pool["yellow"] < c_yellow: return false
	return true

## Deducts the specified amounts from the mana pool.
## Should only be called after has_enough_mana() returns true.
func consume_mana(c_red: int, c_blue: int, c_green: int, c_yellow: int):
	mana_pool["red"] -= c_red
	mana_pool["blue"] -= c_blue
	mana_pool["green"] -= c_green
	mana_pool["yellow"] -= c_yellow
	_update_mana_ui()

# 1. TURN CONTROL UI
## Updates the moves counter UI.
## Changes the text color to RED when moves reach 0.
func _on_moves_updated(amount: int):
	if moves_label:
		moves_label.text = "Moves: " + str(amount)
		if amount == 0:
			moves_label.modulate = Color.RED
			
		else:
			moves_label.modulate = Color.WHITE

# --- MAIN COMBAT LOGIC ---

## Core callback when a match occurs in the Grid.
## 1. Generates Mana based on Tile ID.
## 2. Deals direct damage if Red Tiles (Bombs) are matched.
## 3. Triggers passive minion attacks (Kraken Tentacles).
## @param type: Integer ID of the tile (0:Red, 1:Blue, 2:Green, 3:Yellow).
func _on_match_made(type: int, amount: int):
	if not is_player_turn: return
	
	# 1. Gain Mana based on Tile ID
	match type:
		0: add_mana("red", amount)    # Bombs (Red)
		1: add_mana("blue", amount)   # Scrolls (Blue)
		2: add_mana("green", amount)  # Shields (Green)
		3: add_mana("yellow", amount) # Gold (Yellow)
	
	# 2. Damage Logic (Red Bombs - ID 0)
	if type == 0: 
		var damage = 0
		if amount == 3: damage = DMG_MATCH_3
		elif amount == 4: damage = DMG_MATCH_4
		elif amount >= 5: damage = DMG_MATCH_5
		
		apply_damage_to_enemy(damage)
		print("PLAYER: Match Red -> Damage: ", damage)
	
	# --- KRAKEN LOGIC (PASSIVE) ---
	# If tentacles exist, they attack automatically on every match.
	if active_tentacles.size() > 0:
		var total_tentacle_damage = 0
		for i in active_tentacles.size():
			# Each tentacle deals 2% of CURRENT enemy HP
			var dmg = int(enemy_hp * 0.02)
			if dmg < 1: dmg = 1
			total_tentacle_damage += dmg
		
		apply_damage_to_enemy(total_tentacle_damage)
		print("Kraken: ", active_tentacles.size(), " tentacles attacked for ", total_tentacle_damage, " extra damage.")

# 3. APPLY DAMAGE TO ENEMY
## Reduces Enemy HP and updates the UI.
## Checks for Victory condition (Enemy HP = 0).
func apply_damage_to_enemy(dmg: int):
	# If the game is already over, do nothing
	if enemy_hp <= 0 or player_hp <= 0: return

	enemy_hp -= dmg
	if enemy_hp < 0: enemy_hp = 0
	update_ui_text()
	
	if enemy_hp == 0:
		print("ENEMY DEFEATED! -> GAME OVER")
		# Change turn text to visually notify the player
		if turn_label: turn_label.text = "VICTORY!"
		# Notify everyone that the game is over (Input locked)
		SignalBus.game_over.emit(true)

# 4. ENEMY PHASE (SIMULATED AI - 3 ACTIONS)
## Starts the Enemy Turn sequence.
## Uses a coroutine to simulate "thinking time" between 3 distinct actions.
func start_enemy_phase():
	print("--- STARTING ENEMY PHASE ---")
	is_player_turn = false
	if turn_label: turn_label.text = "Turn: ENEMY"
	
	# Wait and Attack Routine (Coroutine)
	# Action 1
	await get_tree().create_timer(1.0).timeout
	if player_hp > 0: enemy_attack_action(1) # HP Check
	
	# Action 2
	await get_tree().create_timer(1.0).timeout
	if player_hp > 0: enemy_attack_action(2) # HP Check
	
	# Action 3
	await get_tree().create_timer(1.0).timeout
	if player_hp > 0: enemy_attack_action(3) # HP Check
	
	# End of turn (Only return turn if NO ONE died)
	await get_tree().create_timer(0.5).timeout
	if player_hp > 0 and enemy_hp > 0:
		return_turn_to_player()

## Executes a single enemy attack.
## Calculates RNG damage and applies it to the player via player_take_damage().
func enemy_attack_action(action_number: int):
	# If game ended (e.g., player died in previous action), stop.
	if player_hp <= 0 or enemy_hp <= 0: return

	var dmg = randi_range(2, 4)
	
	# --- CRITICAL CHANGE ---
	# Calls the damage handler that respects shields/defense
	player_take_damage(dmg) 
	# ---------------------------
	
	print("ENEMY: Action ", action_number, " -> Deals ", dmg, " damage.")

# 5. RETURN TURN TO PLAYER
## Ends the enemy phase and restores control to the player.
## Emits a signal to reset the grid moves to 3.
func return_turn_to_player():
	print("--- BACK TO PLAYER ---")
	is_player_turn = true
	if turn_label: turn_label.text = "Turn: PLAYER"
	
	# Notify GridManager to reset moves to 3
	SignalBus.enemy_turn_finished.emit()

# 6. UPDATE GENERAL UI
## Refreshes the text labels for HP and Turn status.
func update_ui_text():
	if player_hp_label:
		player_hp_label.text = "Player HP: " + str(player_hp) + "/" + str(MAX_HP)
	
	if enemy_hp_label:
		enemy_hp_label.text = "Enemy HP: " + str(enemy_hp) + "/" + str(MAX_HP)
	
	if turn_label:
		if is_player_turn: turn_label.text = "Turn: PLAYER"

## Callback triggered when the grid is completely stable (cascades finished).
## Starts the Enemy Phase only if it was the player's turn.
func _on_player_turn_ended_safely():
	if is_player_turn:
		print("Cascades finished. Starting Enemy Phase...")
		start_enemy_phase()

# ================================================================
#                ABILITY SYSTEM (PHASE 1)
# ================================================================

## Emits a signal updating the UI with the current mana pool dictionary.
func _update_mana_ui():
	# Emit the Dictionary, not an int
	SignalBus.mana_updated.emit(mana_pool)

# --- ACTIVATION LOGIC ---

## Attempts to activate a specific ability.
## Performs validation checks:
## 1. Is it the player's turn?
## 2. Is the grid stable?
## 3. Does the player have enough colored mana?
## If valid, consumes mana and executes the ability.
func try_activate_ability(ability: Ability) -> bool:
	if not is_player_turn: return false
	if grid_manager and grid_manager.is_processing: return false
	
	# Validation by color
	if not has_enough_mana(ability.cost_red, ability.cost_blue, ability.cost_green, ability.cost_yellow):
		print("❌ Not enough colored mana!")
		return false

	print("✅ Activating: ", ability.ability_name)
	
	# Consume specific colors
	consume_mana(ability.cost_red, ability.cost_blue, ability.cost_green, ability.cost_yellow)
	
	ability.execute(self)
	update_ui_text()
	return true

## Handles damage received by the player.
## Applies defensive logic (e.g., Shields/Walls) before reducing HP.
## Checks for Defeat condition (Player HP = 0).
func player_take_damage(amount: int):
	# Check if damage reduction (Shield) is active
	if damage_reduction_next_hit > 0.0:
		print("CombatManager: Damage reduced by shield: ", damage_reduction_next_hit * 100, "%")
		amount = int(amount * (1.0 - damage_reduction_next_hit))
		
		# If reduction was 100% or more, reset the shield after the hit
		if damage_reduction_next_hit >= 1.0:
			damage_reduction_next_hit = 0.0
	
	player_hp -= amount
	if player_hp < 0: player_hp = 0
	update_ui_text()
	
	if player_hp == 0:
		print("PLAYER DEFEATED!")
		SignalBus.game_over.emit(false)
