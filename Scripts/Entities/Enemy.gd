extends Node2D
class_name EnemyShip

@export var cannonball_scene: PackedScene
@onready var state_machine = $StateMachine
@onready var sprite = $AnimatedSprite2D
@onready var cannon_spawn = $CannonSpawn
@onready var hull_shadow = $HullShadow

# --- BOBBING VARIABLES ---
var time_passed: float = 0.0
var bob_frequency: float = 1.5
const MAX_EVASION_DRIFT = 20.0
var base_pos_x: float
var base_pos_y: float
var base_scale: Vector2
var pending_damage: int = 0
var last_damage_received: int = 0
var pending_miss: bool = false
var pending_bombs: int = 1

func _ready():
	base_pos_x = position.x
	base_pos_y = position.y
	base_scale = sprite.scale
	for child in state_machine.get_children():
		if child is State:
			child.context = self
			child.state_machine = state_machine
			
	state_machine.change_state(state_machine.get_node("Idle"))
	sprite.play("default")
	
	
	SignalBus.enemy_attack_requested.connect(_on_attack_requested)
	SignalBus.enemy_damaged.connect(_on_enemy_damaged) 
	SignalBus.game_over.connect(_on_game_over)
	SignalBus.enemy_helm_match_animation.connect(_play_evasion_glow)

func _process(delta: float):
	time_passed += delta
	var wave_offset = sin(time_passed * bob_frequency) * 3.0
	
	if hull_shadow:
		var current_alpha = 0.90 + (wave_offset * 0.02)
		# Mantenemos el negro puro con el alpha dinámico que logramos antes
		hull_shadow.modulate = Color(0.0, 0.0, 0.0, current_alpha)

func _on_attack_requested(dmg: int, is_miss: bool = false, bomb_count: int = 1): 
	pending_damage = dmg
	pending_miss = is_miss 
	pending_bombs = bomb_count 
	state_machine.change_state(state_machine.get_node("Attack"))

func _on_enemy_damaged(amount: int):
	last_damage_received = amount
	state_machine.change_state(state_machine.get_node("TakeDamage"))


func _on_game_over(player_won: bool):
	
	if player_won:
		state_machine.change_state(state_machine.get_node("Die"))
		

func _play_evasion_glow():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Brillo divino rápido (0.3s)
	tween.tween_property(self, "modulate", Color(1.3, 1.5, 1.5), 0.3).set_trans(Tween.TRANS_SINE)
	
	# Calculamos dónde debe ir basado en su nivel de evasión actual
	var target_x = base_pos_x
	var combat_manager = get_tree().current_scene.get_node_or_null("CombatManager")
	if combat_manager:
		var drift_percent = combat_manager.enemy_evasion / 0.50
		# Sumamos porque el enemigo va hacia la derecha
		target_x = base_pos_x + (MAX_EVASION_DRIFT * drift_percent)
	
	# Movimiento muy lento y fluido hacia la nueva posición (1.2 segundos)
	tween.tween_property(self, "position:x", target_x, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	
	# El color vuelve a la normalidad, pero la posición X ya no regresa.
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
func update_damage_vfx():
	var combat_manager = get_tree().current_scene.get_node_or_null("CombatManager")
	if not combat_manager: return
	
	# Calculamos el porcentaje usando la vida del ENEMIGO
	var hp_percent = float(combat_manager.enemy_hp) / float(combat_manager.MAX_HP)
	
	var vfx_75 = get_node_or_null("DamageVFX/Level1_75")
	var vfx_50 = get_node_or_null("DamageVFX/Level2_50")
	var vfx_25 = get_node_or_null("DamageVFX/Level3_25")
	
	# 1. Apagamos todos por seguridad
	if vfx_75: vfx_75.hide()
	if vfx_50: vfx_50.hide()
	if vfx_25: vfx_25.hide()

	# 2. Encendemos el que corresponde
	if hp_percent <= 0.25:
		if vfx_25: vfx_25.show()
	elif hp_percent <= 0.50:
		if vfx_50: vfx_50.show()
	elif hp_percent <= 0.75:
		if vfx_75: vfx_75.show()
