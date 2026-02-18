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
var player_hp: int = MAX_HP
var enemy_hp: int = MAX_HP
var is_player_turn: bool = true

# --- RESOURCES & STATS ---
var enemy_gold: int = 1000 
var player_gold: int = 0
var player_xp: int = 0      
var player_evasion: float = 0.0 
var enemy_evasion: float = 0.0
var damage_reduction_next_hit: float = 0.0
var is_enemy_magic_blocked: bool = false   
var active_tentacles: Array = [] 

func _ready():
	# Esperamos un frame para asegurar que GameUI haya conectado las señales.
	await get_tree().process_frame
	
	# Enviamos estado inicial a la UI
	update_ui_state()
	_update_mana_ui()
	
	SignalBus.match_found.connect(_on_match_made)
	# SignalBus.moves_updated.connect(_on_moves_updated) <-- YA NO NECESITAMOS ESCUCHAR ESTO AQUÍ
	SignalBus.turn_ended.connect(_on_player_turn_ended_safely)

# --- MANA SYSTEM ---
func add_mana(color_type: String, amount: int):
	if color_type in mana_pool:
		mana_pool[color_type] += amount
		if mana_pool[color_type] > MAX_MANA_PER_COLOR:
			mana_pool[color_type] = MAX_MANA_PER_COLOR
		_update_mana_ui()

func has_enough_mana(c_red: int, c_blue: int, c_green: int) -> bool:
	if mana_pool["red"] < c_red: return false
	if mana_pool["blue"] < c_blue: return false
	if mana_pool["green"] < c_green: return false
	return true

func consume_mana(c_red: int, c_blue: int, c_green: int):
	mana_pool["red"] -= c_red
	mana_pool["blue"] -= c_blue
	mana_pool["green"] -= c_green
	_update_mana_ui()

func _update_mana_ui():
	SignalBus.mana_updated.emit(mana_pool)

# --- CORE LOGIC: MATCH PROCESSING ---
func _on_match_made(type: int, amount: int):
	if not is_player_turn: return
	
	print("Match! Type: ", type, " | Amount: ", amount)
	
	match type:
		0: add_mana("red", amount)
		1: add_mana("blue", amount)
		2: add_mana("green", amount)
		3: # BOMBA
			var bomb_damage = 0
			if amount == 3: bomb_damage = 3
			elif amount == 4: bomb_damage = 5
			elif amount >= 5: bomb_damage = 8
			apply_damage_to_enemy(bomb_damage)
			print("COMBAT: Bomb! Dealt ", bomb_damage, " damage.")
		4: # TIMÓN
			var evasion_boost = 0.0
			if amount == 3: evasion_boost = 0.10
			elif amount == 4: evasion_boost = 0.15
			elif amount >= 5: evasion_boost = 0.20
			player_evasion += evasion_boost
			if player_evasion > 0.9: player_evasion = 0.9
			print("COMBAT: Evasion Up! Enemy Miss Chance: ", player_evasion * 100, "%")
		5: # MONEDA
			var gold_gained = amount * 100
			player_gold += gold_gained
			print("LOOT: Gained ", gold_gained, " Gold. Total: ", player_gold)
		6: # PERGAMINO
			var xp_gained = 0
			if amount == 3: xp_gained = 100
			elif amount == 4: xp_gained = 500
			elif amount >= 5: xp_gained = 800
			player_xp += xp_gained
			print("PROGRESS: Gained ", xp_gained, " XP. Total: ", player_xp)
	
	# FIX KRAKEN/LEVIATHAN
	if active_tentacles.size() > 0 and not grid_manager.is_cascading:
		var total_tentacle_damage = 0
		for i in active_tentacles.size():
			var dmg = int(enemy_hp * 0.02)
			if dmg < 1: dmg = 1
			total_tentacle_damage += dmg
		apply_damage_to_enemy(total_tentacle_damage)
		print("Kraken: Tentacles attacked for ", total_tentacle_damage)

# --- DAMAGE & TURNS ---
func apply_damage_to_enemy(dmg: int):
	if enemy_hp <= 0: return
	enemy_hp -= dmg
	if enemy_hp < 0: enemy_hp = 0
	
	update_ui_state() # Notificamos el cambio
	
	if enemy_hp == 0:
		print("VICTORY!")
		# TODO: Emitir señal de victoria UI si es necesario
		SignalBus.game_over.emit(true)

func player_take_damage(amount: int):
	# 1. Chequeo de Evasión
	var hit_chance = randf()
	if hit_chance < player_evasion:
		print("MISS! Evasion (", player_evasion * 100, "%) saved you.")
		return

	# 2. Chequeo de Reducción de Daño
	if damage_reduction_next_hit > 0.0:
		print("SHIELD ACTIVE! Damage reduced by ", damage_reduction_next_hit * 100, "%")
		amount = int(amount * (1.0 - damage_reduction_next_hit))
		damage_reduction_next_hit = 0.0

	# 3. Aplicar Daño
	player_hp -= amount
	if player_hp < 0: player_hp = 0
	
	update_ui_state() # Notificamos el cambio
	
	if player_hp == 0:
		print("DEFEAT!")
		SignalBus.game_over.emit(false)

# --- UI HELPER ---
func update_ui_state():
	# Ahora solo emitimos señales, no tocamos Labels
	SignalBus.player_hp_changed.emit(player_hp, MAX_HP)
	SignalBus.enemy_hp_changed.emit(enemy_hp, MAX_HP)
	# Si quisieras avisar del turno:
	# SignalBus.turn_changed.emit("PLAYER" if is_player_turn else "ENEMY")

# --- TURN FLOW ---
func _on_player_turn_ended_safely():
	if is_player_turn: start_enemy_phase()

func start_enemy_phase():
	is_player_turn = false
	# UI Update via Signal (Pendiente si agregas un label de turno en GameUI)
	
	await get_tree().create_timer(1.0).timeout
	if player_hp > 0: enemy_attack_action(1)
	await get_tree().create_timer(1.0).timeout
	if player_hp > 0: enemy_attack_action(2)
	await get_tree().create_timer(1.0).timeout
	if player_hp > 0: enemy_attack_action(3)
	await get_tree().create_timer(0.5).timeout
	if player_hp > 0 and enemy_hp > 0: return_turn_to_player()

func enemy_attack_action(action_number: int):
	if player_hp <= 0 or enemy_hp <= 0: return
	if is_enemy_magic_blocked: print("Enemy Silenced! Attack skipped.")
	var dmg = randi_range(2, 4)
	player_take_damage(dmg)
	print("Enemy Action ", action_number, " executed.")

func return_turn_to_player():
	is_player_turn = true
	SignalBus.enemy_turn_finished.emit()

# --- ABILITY ACTIVATION ---
func try_activate_ability(ability: Ability) -> bool:
	if not is_player_turn: return false
	if grid_manager and grid_manager.is_processing: return false
	
	# FIX 1: EVITAR MOVIMIENTOS NEGATIVOS
	if ability.ability_name != "Treasure Seeker":
		if grid_manager.current_moves <= 0:
			print("CombatManager: No moves left to use ability!")
			return false
	
	if not has_enough_mana(ability.cost_red, ability.cost_blue, ability.cost_green):
		print("Not enough mana")
		return false
	
	# 1. Consumir Maná
	consume_mana(ability.cost_red, ability.cost_blue, ability.cost_green)
	
	# 2. FEEDBACK VISUAL
	if ability.icon_magic:
		# play_magic_animation(ability.icon_magic) 
		# TODO: Emitir señal: SignalBus.ability_cast.emit(ability.icon_magic)
		pass
	
	# 3. Ejecutar Lógica
	ability.execute(self)
	update_ui_state()
	
	# FIX: CONSUMO DE TURNO
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
