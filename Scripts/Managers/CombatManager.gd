extends Control

class_name CombatManager

@onready var health_bar = $ProgressBar
@onready var enemy_sprite = $TextureRect
@onready var moves_label = $MovesLabel 

var max_health: int = 100
var current_health: int = 100

# --- MANA SYSTEM ---
var mana_red: int = 0
var mana_blue: int = 0
var mana_green: int = 0
var mana_yellow: int = 0

# --- ABILITY SYSTEM ---
# This list will allow dragging abilities from the inspector in the future
@export var equipped_abilities: Array[Ability] = []

func _ready():
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Connect to the global signal to listen for matches from the GridManager
	SignalBus.match_found.connect(_on_match_made)
	
	# Listen for changes in available moves
	SignalBus.moves_updated.connect(_on_moves_updated)

## Updates the UI label displaying the remaining moves.
## Triggered by the SignalBus when the turn state changes.
func _on_moves_updated(amount: int):
	if moves_label:
		moves_label.text = "Moves: " + str(amount)
		
		# Optional: Change color if running low on moves
		if amount == 0:
			moves_label.modulate = Color.RED
		else:
			moves_label.modulate = Color.WHITE

## Handles logic when a match is made: accumulates mana and deals damage.
## @param type: The color ID of the tile (0:Red, 1:Blue, 2:Green, 3:Yellow).
## @param amount: The number of tiles destroyed.
func _on_match_made(type: int, amount: int):
	# 1. ACCUMULATE MANA
	# Assuming these ID orders: 0:Red, 1:Blue, 2:Green, 3:Yellow
	match type:
		0: 
			mana_red += amount
			print("Mana RED +", amount, " | Total: ", mana_red)
		1: 
			mana_blue += amount
			print("Mana BLUE +", amount, " | Total: ", mana_blue)
		2: 
			mana_green += amount
			print("Mana GREEN +", amount, " | Total: ", mana_green)
		3: 
			mana_yellow += amount
			print("Mana YELLOW +", amount, " | Total: ", mana_yellow)
	
	# 2. CALCULATE DAMAGE (Keeping previous logic or simplifying)
	var damage = 0
	match type:
		0: damage = amount * 10 
		1: damage = amount * 5
		2: damage = amount * 2
		3: damage = amount * 5
		_: damage = amount 
	
	# 3. APPLY DAMAGE
	if damage > 0:
		take_damage(damage)

## Reduces enemy health and plays impact animations.
## Handles the tweening of the health bar and the flash effect on the sprite.
func take_damage(amount: int):
	current_health -= amount
	if current_health < 0: current_health = 0
	
	var tween = create_tween()
	tween.tween_property(health_bar, "value", current_health, 0.3).set_trans(Tween.TRANS_SINE)
	
	var flash_tween = create_tween()
	enemy_sprite.modulate = Color(10, 10, 10) 
	flash_tween.tween_property(enemy_sprite, "modulate", Color.RED, 0.2) 
	
	print("Enemy received ", amount, " damage. Remaining health: ", current_health)
	
	if current_health == 0:
		die()

## Handles the enemy defeat sequence.
## Hides the enemy and reloads the scene after a delay.
func die():
	print("¡Defeated enemy!")
	enemy_sprite.hide()
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

## Attempts to use the ability in slot 'index' (0, 1, 2...).
## Returns TRUE if cast successfully, FALSE if not enough mana.
func try_cast_ability(index: int) -> bool:
	# 1. Basic validation (Does the ability exist?)
	if index < 0 or index >= equipped_abilities.size():
		print("Error: No ability in slot ", index)
		return false
		
	var ability = equipped_abilities[index]
	
	# 2. Cost Check (Do I have enough mana?)
	var has_red = mana_red >= ability.cost_red
	var has_blue = mana_blue >= ability.cost_blue
	var has_green = mana_green >= ability.cost_green
	var has_yellow = mana_yellow >= ability.cost_yellow
	
	if has_red and has_blue and has_green and has_yellow:
		# 3. PAY (Subtract mana)
		mana_red -= ability.cost_red
		mana_blue -= ability.cost_blue
		mana_green -= ability.cost_green
		mana_yellow -= ability.cost_yellow
		
		# 4. EXECUTE
		print("Casting Ability: ", ability.ability_name)
		print("Mana Left -> R:", mana_red, " B:", mana_blue, " G:", mana_green, " Y:", mana_yellow)
		
		# We pass 'enemy_sprite' as the default target
		ability.execute(enemy_sprite) 
		return true
	else:
		print("Not enough mana for: ", ability.ability_name)
		return false
