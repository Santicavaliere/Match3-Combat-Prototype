extends Resource
class_name Ability

## BASE CLASS FOR ABILITIES (TEMPLATE)
## Defines the data structure for active skills.

@export_group("Identity")
@export var ability_name: String = "Skill Name"
@export_multiline var description: String = "Skill Description"

# --- NUEVA SECCIÓN VISUAL ---
@export_subgroup("Visuals")
@export var icon_talisman: Texture2D  # Imagen para el botón (UI)
@export var icon_magic: Texture2D     # Imagen del efecto en pantalla (Overlay)

@export_group("Costs")
@export var cost_red: int = 0
@export var cost_blue: int = 0
@export var cost_green: int = 0

## Virtual Function: Executes the ability's logic.
func execute(combat_manager: Node):
	print("Base ability executed (No logic implemented).")
