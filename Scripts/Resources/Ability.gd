extends Resource
class_name Ability

## CLASE BASE (MOLDE) PARA HABILIDADES
## Este script define qué datos tiene CUALQUIER habilidad del juego.
## Al usar 'class_name Ability', Godot nos dejará crear habilidades en el inspector.

@export_group("Identity")
@export var ability_name: String = "Fireball"
@export_multiline var description: String = "Deals damage to the enemy."
@export var icon: Texture2D
@export_group("Mana Costs")

@export var cost_red: int = 0
@export var cost_blue: int = 0
@export var cost_green: int = 0
@export var cost_yellow: int = 0

## Función virtual: Esto es lo que hace la habilidad.
## Las habilidades específicas (ej: ExplosionAbility) sobreescribirán esto.
func execute(target: Node):
	print("Executing ability base: ", ability_name)
