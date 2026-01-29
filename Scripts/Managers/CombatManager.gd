extends Control

class_name CombatManager

# We maintain only the reference to the moves label, as it is the only visual element allowed for this milestone.
@onready var moves_label = $MovesLabel 

# --- BACKEND DATA (Stored in memory) ---
var max_health: int = 100
var current_health: int = 100

# --- MANA SYSTEM (Kept to show logs in the console) ---
var mana_red: int = 0
var mana_blue: int = 0
var mana_green: int = 0
var mana_yellow: int = 0

# --- ABILITY SYSTEM ---
@export var equipped_abilities: Array[Ability] = []

func _ready():
	# Connect to the global signal bus
	SignalBus.match_found.connect(_on_match_made)
	SignalBus.moves_updated.connect(_on_moves_updated)

## Updates the moves text (This is valid for Milestone 3)
func _on_moves_updated(amount: int):
	if moves_label:
		moves_label.text = "Moves: " + str(amount)
		
		# Simple visual feedback: Change color to red if moves reach 0
		if amount == 0:
			moves_label.modulate = Color.RED
		else:
			moves_label.modulate = Color.WHITE

## Pure Backend Logic: Accumulates mana and prints to console.
func _on_match_made(type: int, amount: int):
	# 1. ACCUMULATE MANA
	match type:
		0: 
			mana_red += amount
			print("Backend Log: Mana RED +", amount, " | Total: ", mana_red)
		1: 
			mana_blue += amount
			print("Backend Log: Mana BLUE +", amount, " | Total: ", mana_blue)
		2: 
			mana_green += amount
			print("Backend Log: Mana GREEN +", amount, " | Total: ", mana_green)
		3: 
			mana_yellow += amount
			print("Backend Log: Mana YELLOW +", amount, " | Total: ", mana_yellow)
	
	# 2. DAMAGE CALCULATION (Simulated, no visual impact)
	var damage = 0
	match type:
		0: damage = amount * 10 
		1: damage = amount * 5
		2: damage = amount * 2
		3: damage = amount * 5
		_: damage = amount 
	
	if damage > 0:
		print("Backend Log: Calculated Damage -> ", damage, " (Visuals disabled for M3)")
