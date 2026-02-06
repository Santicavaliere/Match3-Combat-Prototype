extends Control

class_name CombatManager

## CORE COMBAT CONTROLLER
## Manages the central loop, resources, and rules based on "Grid Functions PDF".

# --- UI REFERENCES ---
@onready var moves_label = $MovesLabel
@onready var player_hp_label = $DebugPanel/VBoxContainer/PlayerHPLabel
@onready var enemy_hp_label = $DebugPanel/VBoxContainer/EnemyHPLabel
@onready var turn_label = $DebugPanel/VBoxContainer/TurnLabel

# --- NUEVA REFERENCIA VISUAL ---
# Asegúrate de haber creado este nodo en la escena según el Paso 4.1
@onready var magic_overlay = $MagicOverlay 

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
	
	# FIX KRAKEN/LEVIATHAN: Solo atacar si NO es cascada
	# Se necesita acceder a la variable is_cascading del grid_manager
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
	update_ui_text()
	if enemy_hp == 0:
		print("VICTORY!")
		if turn_label: turn_label.text = "VICTORY!"
		SignalBus.game_over.emit(true)

func player_take_damage(amount: int):
	# 1. Chequeo de Evasión (Timón)
	var hit_chance = randf()
	if hit_chance < player_evasion:
		print("MISS! Evasion (", player_evasion * 100, "%) saved you.")
		return

	# 2. Chequeo de Reducción de Daño (Muro / Escudos) <-- NUEVO BLOQUE
	if damage_reduction_next_hit > 0.0:
		print("SHIELD ACTIVE! Damage reduced by ", damage_reduction_next_hit * 100, "%")
		amount = int(amount * (1.0 - damage_reduction_next_hit))
		# Consumir el escudo después del golpe (opcional, suele ser de un solo uso)
		damage_reduction_next_hit = 0.0

	# 3. Aplicar Daño
	player_hp -= amount
	if player_hp < 0: player_hp = 0
	update_ui_text()
	
	if player_hp == 0:
		print("DEFEAT!")
		SignalBus.game_over.emit(false)

# --- UI HELPER ---
func update_ui_text():
	if player_hp_label: player_hp_label.text = "Player HP: " + str(player_hp) + "/" + str(MAX_HP)
	if enemy_hp_label: enemy_hp_label.text = "Enemy HP: " + str(enemy_hp) + "/" + str(MAX_HP)
	if turn_label: if is_player_turn: turn_label.text = "Turn: PLAYER"

# --- TURN FLOW ---
func _on_moves_updated(amount: int):
	if moves_label:
		moves_label.text = "Moves: " + str(amount)
		moves_label.modulate = Color.RED if amount == 0 else Color.WHITE

func _on_player_turn_ended_safely():
	if is_player_turn: start_enemy_phase()

func start_enemy_phase():
	is_player_turn = false
	if turn_label: turn_label.text = "Turn: ENEMY"
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
	if turn_label: turn_label.text = "Turn: PLAYER"
	SignalBus.enemy_turn_finished.emit()

# --- ABILITY ACTIVATION & MAGIC VISUALS ---
func try_activate_ability(ability: Ability) -> bool:
	if not is_player_turn: return false
	if grid_manager and grid_manager.is_processing: return false
	
	# --- FIX 1: EVITAR MOVIMIENTOS NEGATIVOS ---
	# Si la habilidad cuesta turno y ya no tengo movimientos, NO ejecutar.
	if ability.ability_name != "Treasure Seeker":
		if grid_manager.current_moves <= 0:
			print("CombatManager: No moves left to use ability!")
			return false
	# -------------------------------------------
	
	if not has_enough_mana(ability.cost_red, ability.cost_blue, ability.cost_green):
		print("Not enough mana")
		return false
	
	# 1. Consumir Maná
	consume_mana(ability.cost_red, ability.cost_blue, ability.cost_green)
	
	# 2. FEEDBACK VISUAL (ANIMACIÓN MÁGICA)
	if ability.icon_magic:
		play_magic_animation(ability.icon_magic)
	
	# 3. Ejecutar Lógica
	ability.execute(self)
	update_ui_text()
	
	# --- FIX: CONSUMO DE TURNO ---
	# Si la habilidad NO es "Treasure Seeker", restamos un movimiento.
	# Asegúrate de que el nombre coincida exactamente con el del recurso (Resource)
	if ability.ability_name != "Treasure Seeker": # O el nombre que le hayas puesto
		grid_manager.current_moves -= 1
		SignalBus.moves_updated.emit(grid_manager.current_moves)
		print("Ability used a turn. Moves left: ", grid_manager.current_moves)
		# Chequeo extra por si se quedó sin movimientos
		# --- EL DETALLE CLAVE: SI LLEGAMOS A 0, TERMINAR EL TURNO ---
		if grid_manager.current_moves <= 0:
			print("Moves reached 0 via Ability -> Ending Turn...")
			# Bloqueamos input visualmente para que no pueda spamear
			grid_manager.is_processing = true 
			# Emitimos la señal para que arranque el turno enemigo
			SignalBus.turn_ended.emit()
	
	update_ui_text()
	return true

## Animación "Pop-up" para el ícono de magia (VERSIÓN GODOT 4 FIXED)
func play_magic_animation(texture: Texture2D):
	if not magic_overlay: return
	
	# 1. Configurar la textura y visibilidad
	magic_overlay.texture = texture
	magic_overlay.visible = true
	magic_overlay.modulate.a = 0.0 
	
	# 2. CORRECCIÓN PARA GODOT 4 (La clave del error)
	# Le decimos que ignore el tamaño real de la imagen para poder forzar 512x512
	magic_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Le decimos que mantenga la proporción y la centre dentro de la caja
	magic_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# 3. Forzar las dimensiones de la caja
	magic_overlay.custom_minimum_size = Vector2(512, 512)
	magic_overlay.size = Vector2(512, 512) 
	
	# 4. Pivote al centro de la caja de 512
	magic_overlay.pivot_offset = Vector2(256, 256) 
	
	# 5. Resetear escala inicial
	magic_overlay.scale = Vector2(0.5, 0.5) 
	
	# --- ANIMACIÓN (Tween) ---
	var tween = create_tween()
	
	# Entrada
	tween.tween_property(magic_overlay, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(magic_overlay, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Pausa
	tween.tween_interval(0.7)
	
	# Salida
	tween.tween_property(magic_overlay, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(magic_overlay, "scale", Vector2(1.3, 1.3), 0.3)
	
	# Finalizar
	tween.tween_callback(func(): magic_overlay.visible = false)
