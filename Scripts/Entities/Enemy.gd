extends Node2D
class_name EnemyShip

@export var cannonball_scene: PackedScene
@onready var state_machine = $StateMachine
@onready var sprite = $AnimatedSprite2D
@onready var cannon_spawn = $CannonSpawn

var pending_damage: int = 0
var last_damage_received: int = 0 # Agregamos esto para saber qué número mostrar

func _ready():
	for child in state_machine.get_children():
		if child is State:
			child.context = self
			child.state_machine = state_machine
			
	state_machine.change_state(state_machine.get_node("Idle"))
	sprite.play("default")
	
	# Conectamos las señales
	SignalBus.enemy_attack_requested.connect(_on_attack_requested)
	SignalBus.enemy_damaged.connect(_on_enemy_damaged) # Escucha el daño
	SignalBus.game_over.connect(_on_game_over) # Escucha si se terminó la partida

func _on_attack_requested(dmg: int):
	pending_damage = dmg
	state_machine.change_state(state_machine.get_node("Attack"))

# Función nueva: Cuando recibe daño
func _on_enemy_damaged(amount: int):
	last_damage_received = amount
	state_machine.change_state(state_machine.get_node("TakeDamage"))

# Función nueva: Cuando la vida llega a cero
func _on_game_over(player_won: bool):
	# Si el jugador ganó (true), significa que el enemigo murió
	if player_won:
		state_machine.change_state(state_machine.get_node("Die"))
