extends ScrollContainer

## DEBUG DASHBOARD / ABILITY TESTER
## Generates buttons for abilities using the new Talisman icons.

# --- EXPORTED VARIABLES ---
@export var abilities_to_test: Array[Ability]

# --- INTERNAL REFERENCES ---
var combat_manager: CombatManager
@onready var container_grid = $GridContainer 
var mana_label: Label 

func _ready():
	combat_manager = get_parent()
	mana_label = get_parent().find_child("ManaLabel")
	
	if not combat_manager:
		print("CRITICAL ERROR: AbilityTester could not find CombatManager.")
		return

	SignalBus.mana_updated.connect(_update_mana_display)

	_create_cheat_button()
	_create_ability_buttons()
	_update_mana_display(combat_manager.mana_pool)

func _update_mana_display(pool: Dictionary):
	if mana_label:
		mana_label.text = "🔴 %d | 🔵 %d | 🟢 %d" % [pool["red"], pool["blue"], pool["green"]]

func _create_cheat_button():
	var btn = Button.new()
	btn.text = "⚡ FULL MANA"
	btn.modulate = Color.GREEN_YELLOW
	btn.focus_mode = Control.FOCUS_NONE
	
	btn.pressed.connect(func():
		combat_manager.mana_pool = {"red": 50, "blue": 50, "green": 50}
		combat_manager._update_mana_ui()
		print("TEST: Infinite Mana Activated!")
	)
	container_grid.add_child(btn)

func _create_ability_buttons():
	if abilities_to_test.is_empty():
		print("WARNING: No abilities loaded in AbilityTester Inspector.")
		return

	for ability in abilities_to_test:
		if ability == null: continue
			
		var btn = Button.new()
		
		# --- VISUAL UPDATE: TALISMANES ---
		# Si la habilidad tiene un icono de talismán, lo usamos.
		if ability.icon_talisman:
			btn.icon = ability.icon_talisman
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			# Tamaño fijo para que se vean uniformes y cuadrados
			btn.custom_minimum_size = Vector2(70, 70)
			# Ponemos el texto en el tooltip para limpiar la UI
			btn.tooltip_text = "%s\nCost: R:%d B:%d G:%d" % [ability.ability_name, ability.cost_red, ability.cost_blue, ability.cost_green]
		else:
			# Fallback si olvidaste asignar la imagen: Texto clásico
			var cost_text = "R:%d B:%d G:%d" % [ability.cost_red, ability.cost_blue, ability.cost_green]
			btn.text = "%s\n(%s)" % [ability.ability_name, cost_text]
			btn.custom_minimum_size = Vector2(100, 40)

		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		btn.pressed.connect(func():
			combat_manager.try_activate_ability(ability)
		)
		
		container_grid.add_child(btn)
