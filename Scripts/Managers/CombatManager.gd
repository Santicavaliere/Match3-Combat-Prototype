extends Control

class_name CombatManager

## CORE COMBAT CONTROLLER
## Manages the central loop, resources, and rules based on "Grid Functions PDF".

# --- UI REFERENCES ---
@onready var moves_label = $MovesLabel
@onready var player_hp_label = $DebugPanel/VBoxContainer/PlayerHPLabel
@onready var enemy_hp_label = $DebugPanel/VBoxContainer/EnemyHPLabel
@onready var turn_label = $DebugPanel/VBoxContainer/TurnLabel

# --- EXTERNAL REFERENCES ---
@export var grid_manager: GridManager

# --- CONFIGURATION ---
const MAX_HP = 50 
const MAX_MANA_PER_COLOR = 50 

# --- GAME STATE ---
var mana_pool = {
	"red": 0,
	"blue": 0,
	"green": 0
}

var player_hp: int = MAX_HP
var enemy_hp: int = MAX_HP
var is_player_turn: bool = true

# --- RESOURCES & STATS ---
var enemy_gold: int = 1000 
var player_gold: int = 0
var player_xp: int = 0      

# --- ESTADÍSTICAS DE BATALLA (TIMÓN) ---
# Representa la probabilidad (0.0 a 1.0) de que el enemigo falle su disparo contra nosotros.
# Según el PDF: Match de timones aumenta este porcentaje[cite: 31, 34].
var player_evasion: float = 0.0 

var is_enemy_magic_blocked: bool = false   
var active_tentacles: Array = [] 

func _ready():
	update_ui_text()
	_update_mana_ui()
	
	SignalBus.match_found.connect(_on_match_made)
	SignalBus.moves_updated.connect(_on_moves_updated)
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
# Implementación estricta del PDF
func _on_match_made(type: int, amount: int):
	if not is_player_turn: return
	
	print("Match! Type: ", type, " | Amount: ", amount)
	
	match type:
		0: # RUBÍ -> Maná Rojo
			add_mana("red", amount)
			
		1: # ZAFIRO -> Maná Azul
			add_mana("blue", amount)
			
		2: # ESMERALDA -> Maná Verde
			add_mana("green", amount)
			
		3: # BOMBA -> Ataque Directo [cite: 2]
			# Reglas PDF: Match 3->3, Match 4->5, Match 5->8 
			var bomb_damage = 0
			if amount == 3: bomb_damage = 3
			elif amount == 4: bomb_damage = 5
			elif amount >= 5: bomb_damage = 8
			# (Si haces un match gigante de 6 o 7, mantenemos 8 o escalamos, 
			# por ahora dejamos 8 como máximo base según PDF)
			
			apply_damage_to_enemy(bomb_damage)
			print("COMBAT: Bomb! Dealt ", bomb_damage, " damage.")
			
		4: # TIMÓN -> Evasión [cite: 17]
			# Reglas PDF: Match 3->10%, Match 4->15%, Match 5->20% 
			var evasion_boost = 0.0
			if amount == 3: evasion_boost = 0.10
			elif amount == 4: evasion_boost = 0.15
			elif amount >= 5: evasion_boost = 0.20
			
			# Sumamos a la evasión del jugador (probabilidad de que el enemigo falle)
			player_evasion += evasion_boost
			
			# Tope máximo lógico (ej: 90%) para no romper el juego
			if player_evasion > 0.9: player_evasion = 0.9
				
			print("COMBAT: Evasion Up! Enemy Miss Chance: ", player_evasion * 100, "%")
			
		5: # MONEDA -> Economía [cite: 56]
			# Regla PDF: Cada moneda eliminada = 100 oro 
			# "No importa si es match de 3, 4 o 5" 
			var gold_gained = amount * 100
			
			player_gold += gold_gained
			print("LOOT: Gained ", gold_gained, " Gold. Total: ", player_gold)
			
		6: # PERGAMINO -> Experiencia [cite: 43]
			# Reglas PDF: 3->100 XP, 4->500 XP, 5->800 XP 
			var xp_gained = 0
			if amount == 3: xp_gained = 100
			elif amount == 4: xp_gained = 500
			elif amount >= 5: xp_gained = 800
			
			player_xp += xp_gained
			print("PROGRESS: Gained ", xp_gained, " XP. Total: ", player_xp)

	# --- KRAKEN PASSIVE ---
	if active_tentacles.size() > 0:
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
	update_ui_text()
	
	if enemy_hp == 0:
		print("VICTORY!")
		if turn_label: turn_label.text = "VICTORY!"
		SignalBus.game_over.emit(true)

func player_take_damage(amount: int):
	# LÓGICA DE TIMÓN (EVASIÓN)
	# Verificamos si el enemigo falla el tiro basado en nuestra evasión
	var hit_chance = randf() # Número aleatorio entre 0.0 y 1.0
	
	if hit_chance < player_evasion:
		print("MISS! Enemy attack failed due to Evasion (", player_evasion * 100, "%)")
		# Feedback visual en consola
		return # ¡No recibimos daño!
	
	# Si acierta, recibimos el daño
	player_hp -= amount
	if player_hp < 0: player_hp = 0
	update_ui_text()
	
	if player_hp == 0:
		print("DEFEAT!")
		SignalBus.game_over.emit(false)

# --- UI HELPER ---
func update_ui_text():
	if player_hp_label:
		player_hp_label.text = "Player HP: " + str(player_hp) + "/" + str(MAX_HP)
	if enemy_hp_label:
		enemy_hp_label.text = "Enemy HP: " + str(enemy_hp) + "/" + str(MAX_HP)
	if turn_label:
		if is_player_turn: turn_label.text = "Turn: PLAYER"

# --- TURN FLOW ---
func _on_moves_updated(amount: int):
	if moves_label:
		moves_label.text = "Moves: " + str(amount)
		moves_label.modulate = Color.RED if amount == 0 else Color.WHITE

func _on_player_turn_ended_safely():
	if is_player_turn:
		start_enemy_phase()

func start_enemy_phase():
	is_player_turn = false
	if turn_label: turn_label.text = "Turn: ENEMY"
	
	# Simulación de turno enemigo
	await get_tree().create_timer(1.0).timeout
	if player_hp > 0: enemy_attack_action(1)
	
	await get_tree().create_timer(1.0).timeout
	if player_hp > 0: enemy_attack_action(2)
	
	await get_tree().create_timer(1.0).timeout
	if player_hp > 0: enemy_attack_action(3)
	
	await get_tree().create_timer(0.5).timeout
	if player_hp > 0 and enemy_hp > 0:
		return_turn_to_player()

func enemy_attack_action(action_number: int):
	if player_hp <= 0 or enemy_hp <= 0: return
	
	if is_enemy_magic_blocked:
		print("Enemy is Silenced! Cannot attack (Simulated).")
	
	var dmg = randi_range(2, 4)
	player_take_damage(dmg) # Aquí adentro se calcula la evasión del Timón
	print("Enemy Action ", action_number, " executed.")

func return_turn_to_player():
	is_player_turn = true
	# IMPORTANTE: Según el PDF, la evasión podría bajar o el enemigo podría subir la suya.
	# Por ahora, mantenemos la evasión acumulada o la reseteamos según prefieras.
	# Si quieres que sea temporal por turno, descomenta la siguiente línea:
	# player_evasion = 0.0 
	
	if turn_label: turn_label.text = "Turn: PLAYER"
	SignalBus.enemy_turn_finished.emit()

func try_activate_ability(ability: Ability) -> bool:
	if not is_player_turn: return false
	if grid_manager and grid_manager.is_processing: return false
	
	if not has_enough_mana(ability.cost_red, ability.cost_blue, ability.cost_green):
		print("Not enough mana")
		return false

	consume_mana(ability.cost_red, ability.cost_blue, ability.cost_green)
	ability.execute(self)
	update_ui_text()
	return true
