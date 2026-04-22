extends Node
class_name CombatManager

## CORE COMBAT CONTROLLER
## Manages the central loop, resources, and rules based on "Grid Functions PDF".
## CLEANED VERSION: Logic Only (No UI Direct References)

# --- EXTERNAL REFERENCES ---
@export var grid_manager: GridManager

# --- CONFIGURATION ---
const MAX_HP = 50 
const MAX_MANA_PER_COLOR = 50 

# --- GAME STATE ---
var mana_pool = { "red": 0, "blue": 0, "green": 0 }
var enemy_mana_pool = { "red": 0, "blue": 0, "green": 0 }
var player_hp: int = MAX_HP
var enemy_hp: int = MAX_HP
var is_player_turn: bool = true

# --- RESOURCES & STATS ---
var enemy_gold: int = 0
var player_gold: int = 0
var enemy_xp: int = 0
var player_xp: int = 0      
var player_evasion: float = 0.0 
var enemy_evasion: float = 0.0
var damage_reduction_next_hit: float = 0.0
var is_enemy_magic_blocked: bool = false   
var active_tentacles: Array = [] 

## Initializes the combat state, synchronizes UI, and connects global signals.
func _ready():
	# Wait one frame to ensure GameUI has connected signals
	await get_tree().process_frame
	
	# Send initial state to UI
	update_ui_state()
	SignalBus.player_gold_changed.emit(player_gold)
	SignalBus.player_xp_changed.emit(player_xp)
	SignalBus.enemy_gold_changed.emit(enemy_gold) 
	SignalBus.enemy_xp_changed.emit(enemy_xp)
	_update_mana_ui()
	
	SignalBus.match_found.connect(_on_match_made)
	SignalBus.turn_ended.connect(_on_player_turn_ended_safely)
	SignalBus.ability_cast_requested.connect(try_activate_ability)
	SignalBus.apply_damage_to_player.connect(player_take_damage)
	SignalBus.evasion_consumed.connect(_on_evasion_consumed)

# --- MANA SYSTEM ---

## Adds mana of a specific color to the pool, clamping to MAX_MANA_PER_COLOR.
func add_mana(color_type: String, amount: int):
	if color_type in mana_pool:
		mana_pool[color_type] += amount
		if mana_pool[color_type] > MAX_MANA_PER_COLOR:
			mana_pool[color_type] = MAX_MANA_PER_COLOR
		_update_mana_ui()

func add_enemy_mana(color_type: String, amount: int):
	if color_type in enemy_mana_pool:
		enemy_mana_pool[color_type] += amount
		if enemy_mana_pool[color_type] > MAX_MANA_PER_COLOR:
			enemy_mana_pool[color_type] = MAX_MANA_PER_COLOR
		
		
		SignalBus.enemy_mana_updated.emit(enemy_mana_pool) 

## Checks if the player has the required mana for an ability.
func has_enough_mana(c_red: int, c_blue: int, c_green: int) -> bool:
	if mana_pool["red"] < c_red: return false
	if mana_pool["blue"] < c_blue: return false
	if mana_pool["green"] < c_green: return false
	return true

## Deducts mana costs from the player's pool.
func consume_mana(c_red: int, c_blue: int, c_green: int):
	mana_pool["red"] -= c_red
	mana_pool["blue"] -= c_blue
	mana_pool["green"] -= c_green
	_update_mana_ui()

func _update_mana_ui():
	SignalBus.mana_updated.emit(mana_pool)

# --- CORE LOGIC: MATCH PROCESSING ---

## Processes match data from the grid, granting resources, triggering attacks, or buffing stats.
func _on_match_made(type: int, amount: int):
	print("Match! Type: ", type, " | Amount: ", amount)
	
	# 1. Guardamos de quién era el turno en el momento exacto de la explosión
	# (Por si el turno cambia mientras el polvo está volando)
	var active_turn_was_player = is_player_turn
	
	# 2. EL FIX VISUAL: El polvo mágico tarda 1.0s en volar a la UI.
	# Si es Maná (0,1,2), Oro (5) o XP (6), pausamos la entrega del premio 1 segundo.
	if type in [0, 1, 2, 5, 6]:
		await get_tree().create_timer(1.0).timeout
		
		# Seguridad: Si el jugador cerró el nivel mientras volaba el polvo, cancelamos.
		if not is_inside_tree(): 
			return
	
	# 3. Entregamos el premio usando la variable guardada
	if active_turn_was_player:
		# --- LÓGICA DEL JUGADOR ---
		match type:
			0: add_mana("red", amount)
			1: add_mana("blue", amount)
			2: add_mana("green", amount)
			3: # BOMB
				var bomb_damage = 1 
				var bullets_to_fire = 4 # Por defecto (Match 3)
				
				if amount == 4: 
					bomb_damage = 2
					bullets_to_fire = 6
				elif amount >= 5: 
					bomb_damage = 2
					bullets_to_fire = 8
					
				var is_miss = (randf() < enemy_evasion)
				
				SignalBus.player_attack_requested.emit(bomb_damage, is_miss, bullets_to_fire)
			4: # HELM
				var boost = 0.10 if amount == 3 else (0.15 if amount == 4 else 0.20)
				_apply_tug_of_war_evasion(true, boost)
			5: # COIN
				player_gold += amount * 100
				SignalBus.player_gold_changed.emit(player_gold) 
			6: # SCROLL
				var xp_gained = 100 if amount == 3 else (500 if amount == 4 else 800)
				player_xp += xp_gained
				SignalBus.player_xp_changed.emit(player_xp) 
				
	else:
		# --- LÓGICA DEL ENEMIGO ---
		match type:
			0: add_enemy_mana("red", amount)
			1: add_enemy_mana("blue", amount)
			2: add_enemy_mana("green", amount)
			3: # BOMB
				var bomb_damage = 1 
				var bullets_to_fire = 4 
				
				if amount == 4: 
					bomb_damage = 2
					bullets_to_fire = 6
				elif amount >= 5: 
					bomb_damage = 2
					bullets_to_fire = 8
					
				var is_miss = (randf() < player_evasion)
				
				SignalBus.enemy_attack_requested.emit(bomb_damage, is_miss, bullets_to_fire)
			4: # HELM
				var boost = 0.10 if amount == 3 else (0.15 if amount == 4 else 0.20)
				_apply_tug_of_war_evasion(false, boost)
			5: # COIN
				enemy_gold += amount * 100
				SignalBus.enemy_gold_changed.emit(enemy_gold) 
			6: # SCROLL
				var xp_gained = 100 if amount == 3 else (500 if amount == 4 else 800)
				SignalBus.enemy_xp_changed.emit(xp_gained)

# --- DAMAGE & TURNS ---

## Applies damage to the enemy, updating UI and checking for victory conditions.
func apply_damage_to_enemy(dmg: int):
	if enemy_hp <= 0: return
	
	enemy_hp -= dmg
	if enemy_hp < 0: enemy_hp = 0
	
	update_ui_state()
	
	# Notify the visual ship to react
	SignalBus.enemy_damaged.emit(dmg)
	
	if enemy_hp == 0:
		print("VICTORY!")
		SignalBus.game_over.emit(true)

## Applies damage to the player, factoring in evasion and shield mechanics.
func player_take_damage(amount: int):
	# 1. Evasion check
	#var hit_chance = randf()
	#if hit_chance < player_evasion:
	#	print("MISS! Evasion (", player_evasion * 100, "%) saved you.")
	#	return
	# 2. Damage reduction check (Shield)
	if damage_reduction_next_hit > 0.0:
		print("SHIELD ACTIVE! Damage reduced by ", damage_reduction_next_hit * 100, "%")
		amount = int(amount * (1.0 - damage_reduction_next_hit))
		damage_reduction_next_hit = 0.0
		
	# 3. Apply damage
	player_hp -= amount
	if player_hp < 0: player_hp = 0
	
	SignalBus.player_damaged.emit(amount)
	update_ui_state()
	
	if player_hp == 0:
		print("DEFEAT!")
		SignalBus.game_over.emit(false)

## Emits current stats to the UI system without direct node manipulation.
func update_ui_state():
	SignalBus.player_hp_changed.emit(player_hp, MAX_HP)
	SignalBus.enemy_hp_changed.emit(enemy_hp, MAX_HP)
	SignalBus.player_evasion_changed.emit(player_evasion)
	SignalBus.enemy_evasion_changed.emit(enemy_evasion)

# --- TURN FLOW ---

func _on_player_turn_ended_safely():
	if is_player_turn: start_enemy_phase()

## Initiates the enemy's attack sequence, now playing physically on the board.
func start_enemy_phase():
	print("--- ENEMY'S TURN BEGINS ---")
	is_player_turn = false
	grid_manager.is_enemy_turn = true
	
	grid_manager.reset_turn() 
	
	await get_tree().create_timer(1.0).timeout 
	
	_play_ai_turn()

## Recursive loop that plays until it runs out of moves.
func _play_ai_turn():
	
	while grid_manager.current_moves > 0 and player_hp > 0 and enemy_hp > 0:
		
		if is_enemy_magic_blocked:
			print("Enemy Silenced! He cannot play the board.")
			break 
		
		while grid_manager.is_processing or grid_manager.is_cascading:
			await get_tree().create_timer(0.2).timeout
			
		
		if _try_enemy_magic():
			grid_manager.current_moves -= 1
			SignalBus.moves_updated.emit(grid_manager.current_moves)
			await get_tree().create_timer(1.5).timeout 
			continue 
		
		
		var ai_move = grid_manager.get_ai_valid_move()
		
		if ai_move.size() == 2:
			
			await grid_manager.execute_ai_move(ai_move[0], ai_move[1])
			
			while grid_manager.is_processing or grid_manager.is_cascading:
				await get_tree().create_timer(0.2).timeout
				
			await get_tree().create_timer(0.8).timeout
		else:
			print("AI: No possible moves found. Failsafe activated.")
			break 
			
	
	if player_hp > 0 and enemy_hp > 0:
		return_turn_to_player()

## Ends the enemy phase and returns control to the player.
func return_turn_to_player():
	is_player_turn = true
	SignalBus.enemy_turn_finished.emit()

# --- ABILITY ACTIVATION ---

## Validates and executes a player ability, consuming mana and turn points if applicable.
func try_activate_ability(ability: Ability) -> bool:
	if not is_player_turn: return false
	if grid_manager and grid_manager.is_processing: return false
	
	# PREVENT NEGATIVE MOVES
	if ability.ability_name != "Treasure Seeker":
		if grid_manager.current_moves <= 0:
			print("CombatManager: No moves left to use ability!")
			return false
	
	if not has_enough_mana(ability.cost_red, ability.cost_blue, ability.cost_green):
		print("Not enough mana")
		return false
	
	# 1. Consume Mana
	consume_mana(ability.cost_red, ability.cost_blue, ability.cost_green)
	
	# 2. Execute Logic
	ability.execute(self)
	update_ui_state()
	
	# Notify UI for success animation
	SignalBus.ability_cast_success.emit(ability)
	
	# TURN CONSUMPTION
	if ability.ability_name != "Treasure Seeker":
		grid_manager.current_moves -= 1
		SignalBus.moves_updated.emit(grid_manager.current_moves)
		print("Ability used a turn. Moves left: ", grid_manager.current_moves)
		
		if grid_manager.current_moves <= 0:
			print("Moves reached 0 via Ability -> Ending Turn...")
			grid_manager.is_processing = true 
			SignalBus.turn_ended.emit()
	
	update_ui_state()
	return true

## AI MAGIC: Checks if the enemy has enough mana to cast any of their abilities.
## Returns true if they cast a spell (to consume their turn/action), or false if they couldn't.
func _try_enemy_magic() -> bool:
	var ui_node = get_tree().current_scene.get_node_or_null("GameUI")
	if not ui_node: return false
	
	
	for ability in ui_node.enemy_equipped_abilities:
		if ability == null: continue
		
		
		if enemy_mana_pool["red"] >= ability.cost_red and \
		   enemy_mana_pool["blue"] >= ability.cost_blue and \
		   enemy_mana_pool["green"] >= ability.cost_green:
			
			print("IA: ¡Maná suficiente para lanzar ", ability.ability_name, "!")
			
			
			enemy_mana_pool["red"] -= ability.cost_red
			enemy_mana_pool["blue"] -= ability.cost_blue
			enemy_mana_pool["green"] -= ability.cost_green
			SignalBus.enemy_mana_updated.emit(enemy_mana_pool)
			
			
			SignalBus.ability_cast_success.emit(ability)
			
			
			ability.execute(self)
			update_ui_state()
			
			return true
			
	return false 

func _apply_tug_of_war_evasion(is_player: bool, amount: float):
	if is_player:
		if enemy_evasion > 0:
			var leftover = amount - enemy_evasion
			enemy_evasion = max(0.0, enemy_evasion - amount)
			if leftover > 0:
				player_evasion = min(player_evasion + leftover, 0.50)
		else:
			player_evasion = min(player_evasion + amount, 0.50)
		SignalBus.helm_match_animation.emit()
	else:
		if player_evasion > 0:
			var leftover = amount - player_evasion
			player_evasion = max(0.0, player_evasion - amount)
			if leftover > 0:
				enemy_evasion = min(enemy_evasion + leftover, 0.50)
		else:
			enemy_evasion = min(enemy_evasion + amount, 0.50)
		SignalBus.enemy_helm_match_animation.emit()
		
	update_ui_state()

func _on_evasion_consumed(is_player_target: bool, amount: float):
	if is_player_target:
		player_evasion = max(0.0, player_evasion - amount)
	else:
		enemy_evasion = max(0.0, enemy_evasion - amount)
	update_ui_state()
