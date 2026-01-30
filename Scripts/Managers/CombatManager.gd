extends Control

class_name CombatManager

## Manages the core combat loop, including HP tracking, Turn states, and Damage logic.
## Handles the communication between the Grid (Match-3) and the Game State.

# --- UI REFERENCES (Ensure paths are correct) ---
@onready var moves_label = $MovesLabel
# Adjust these paths if you placed labels inside containers
@onready var player_hp_label = $DebugPanel/VBoxContainer/PlayerHPLabel
@onready var enemy_hp_label = $DebugPanel/VBoxContainer/EnemyHPLabel
@onready var turn_label = $DebugPanel/VBoxContainer/TurnLabel

# --- CONFIGURATION (PDF RULES) ---
const MAX_HP = 50 
const DMG_MATCH_3 = 3
const DMG_MATCH_4 = 5
const DMG_MATCH_5 = 8

# --- GAME STATE ---
var player_hp: int = MAX_HP
var enemy_hp: int = MAX_HP
var is_player_turn: bool = true

func _ready():
	# Initialize UI
	update_ui_text()
	
	# Connect Signals
	SignalBus.match_found.connect(_on_match_made)
	SignalBus.moves_updated.connect(_on_moves_updated)
	# NEW SECURE CONNECTION: Waits for cascades to finish before changing turns
	SignalBus.turn_ended.connect(_on_player_turn_ended_safely)

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

# 2. PLAYER DAMAGE LOGIC (Backend PDF)
## Handles match events triggered by the GridManager.
## Calculates damage based on the Bomb (Red) rules defined in the design document.
func _on_match_made(type: int, amount: int):
	# If it's not player turn, ignore (prevents visual bugs)
	if not is_player_turn: return

	# We assume TYPE 0 (Red) is the BOMB according to your PDF
	if type == 0: 
		var damage = 0
		
		# APPLYING PDF RULES
		if amount == 3:
			damage = DMG_MATCH_3
		elif amount == 4:
			damage = DMG_MATCH_4
		elif amount >= 5:
			damage = DMG_MATCH_5
		
		apply_damage_to_enemy(damage)
		print("PLAYER: Match of ", amount, " bombs -> Damage: ", damage)

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

## Helper function for the enemy attack logic.
## Deals random damage (placeholder) and checks for Defeat condition.
func enemy_attack_action(action_number: int):
	# If game ended (e.g., player died in previous action), stop.
	if player_hp <= 0 or enemy_hp <= 0: return

	var dmg = randi_range(2, 4)
	player_hp -= dmg
	if player_hp < 0: player_hp = 0
	
	print("ENEMY: Action ", action_number, " -> Deals ", dmg, " damage.")
	update_ui_text()
	
	if player_hp == 0:
		print("PLAYER DEFEATED! -> GAME OVER")
		if turn_label: turn_label.text = "DEFEAT..."
		SignalBus.game_over.emit(false)

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
