extends Control

class_name CombatManager

@onready var health_bar = $ProgressBar
@onready var enemy_sprite = $TextureRect

var max_health: int = 100
var current_health: int = 100

func _ready():
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Connect to the global signal to listen for matches from the GridManager
	SignalBus.match_found.connect(_on_match_made)

## Callback triggered when a match occurs in the GridManager.
## Calculates total damage based on the tile type (color) and the number of tiles destroyed.
## Damage Logic:
## - Type 0 (Red): Heavy Damage (Multiplier x10)
## - Type 1 (Blue): Medium Damage (Multiplier x5)
## - Type 2 (Green): Light Damage (Multiplier x2)
## - Type 3 (Yellow): Medium Damage (Multiplier x5)
func _on_match_made(type: int, amount: int):
	
	var damage = 0
	
	match type:
		0: damage = amount * 10 
		1: damage = amount * 5
		2: damage = amount * 2
		3: damage = amount * 5
		_: damage = amount 
	
	take_damage(damage)

## Applies damage to the enemy and handles visual feedback (UI & FX).
## 1. Updates the health value (clamped to 0).
## 2. Animates the Health Bar using a Tween for smoothness.
## 3. Flashes the enemy sprite white to indicate impact.
func take_damage(amount: int):
	current_health -= amount
	if current_health < 0: current_health = 0
	# UI Animation: Smoothly decrease the health bar
	var tween = create_tween()
	tween.tween_property(health_bar, "value", current_health, 0.3).set_trans(Tween.TRANS_SINE)
	# Visual FX: Flash the enemy sprite (White -> Original Color)
	var flash_tween = create_tween()
	enemy_sprite.modulate = Color(10, 10, 10) 
	flash_tween.tween_property(enemy_sprite, "modulate", Color.RED, 0.2) 
	
	print("Enemy received ", amount, " damage. Remaining health: ", current_health)
	
	if current_health == 0:
		die()

## Handles the defeat sequence when health reaches 0.
## Hides the enemy and reloads the scene after a short delay to restart the loop.
func die():
	print("¡Defeated enemy!")
	
	enemy_sprite.hide()
	
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
