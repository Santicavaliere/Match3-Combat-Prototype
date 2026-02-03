extends ScrollContainer

## DEBUG DASHBOARD / ABILITY TESTER
##
## A temporary UI tool designed to test backend mechanics without needing the full game loop.
## It generates buttons for assigned abilities and displays real-time mana status.

# --- EXPORTED VARIABLES ---

## List of Ability Resources (.tres) to generate buttons for. Drag and drop here in Inspector.
@export var abilities_to_test: Array[Ability]

# --- INTERNAL REFERENCES ---

## Reference to the main logic controller (Parent Node).
var combat_manager: CombatManager

## Reference to the GridContainer where buttons are instantiated.
@onready var container_grid = $GridContainer 

## Reference to the label displaying current mana values.
var mana_label: Label 

# --- INITIALIZATION ---

## Standard Godot lifecycle method.
## Initializes references, checks for dependencies, and builds the initial UI.
func _ready():
	# 1. Locate CombatManager (Parent)
	combat_manager = get_parent()
	
	# 2. Locate ManaLabel (Sibling)
	# Uses find_child to ensure robust retrieval by name.
	mana_label = get_parent().find_child("ManaLabel")
	
	if not combat_manager:
		print("CRITICAL ERROR: AbilityTester could not find CombatManager.")
		return

	# 3. Connect Mana Signal (For real-time UI updates)
	SignalBus.mana_updated.connect(_update_mana_display)

	# 4. Build Interface
	_create_cheat_button()
	_create_ability_buttons()
	
	# 5. Force initial update (prevent empty label on start)
	_update_mana_display(combat_manager.mana_pool)

# --- UI UPDATE FUNCTIONS ---

## Updates the ManaLabel text to reflect the current resource pool.
## Formats the string with colored emojis and values.
## @param pool: A Dictionary containing 'red', 'blue', 'green', and 'yellow' integer values.
func _update_mana_display(pool: Dictionary):
	if mana_label:
		# Format: 🔴 10 | 🔵 5 | 🟢 8 | 🟡 2
		mana_label.text = "🔴 %d | 🔵 %d | 🟢 %d | 🟡 %d" % [pool["red"], pool["blue"], pool["green"], pool["yellow"]]

## Creates a debug 'Cheat' button to instantly refill resources.
## Useful for testing high-cost abilities without grinding matches.
func _create_cheat_button():
	var btn = Button.new()
	btn.text = "⚡ FULL MANA"
	btn.modulate = Color.GREEN_YELLOW
	btn.focus_mode = Control.FOCUS_NONE
	
	# On press: Fill all mana pools to 50 and update UI
	btn.pressed.connect(func():
		combat_manager.mana_pool = {"red": 50, "blue": 50, "green": 50, "yellow": 50}
		combat_manager._update_mana_ui()
		print("TEST: Infinite Mana Activated!")
	)
	container_grid.add_child(btn)

## Iterates through the 'abilities_to_test' array and instantiates a button for each one.
## Handles text formatting (Name + Cost) and signal connection.
func _create_ability_buttons():
	# Safety check for empty array
	if abilities_to_test.is_empty():
		print("WARNING: No abilities loaded in AbilityTester Inspector.")
		return

	for ability in abilities_to_test:
		# Safety check for null slots in the array
		if ability == null:
			continue
			
		var btn = Button.new()
		
		# --- TEXT FORMATTING ---
		# Builds the cost string based on non-zero values.
		var cost_text = ""
		if ability.cost_red > 0: cost_text += "R:%d " % ability.cost_red
		if ability.cost_blue > 0: cost_text += "B:%d " % ability.cost_blue
		if ability.cost_green > 0: cost_text += "G:%d " % ability.cost_green
		if ability.cost_yellow > 0: cost_text += "Y:%d " % ability.cost_yellow
		
		if cost_text == "": cost_text = "FREE"
		
		# Set Button Text: Name on top, Cost below
		btn.text = "%s\n(%s)" % [ability.ability_name, cost_text]
		
		# --- FIX FOR SCROLLING ---
		# Changed from MOUSE_FILTER_STOP to MOUSE_FILTER_PASS.
		# This allows the 'drag' event to pass through the button to the ScrollContainer,
		# enabling swipe-to-scroll on mobile devices.
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Force minimum size to prevent layout squashing
		btn.custom_minimum_size = Vector2(100, 40)
		
		# Connect Action
		btn.pressed.connect(func():
			combat_manager.try_activate_ability(ability)
		)
		
		container_grid.add_child(btn)
