extends Control

class_name CombatManager

@onready var health_bar = $ProgressBar
@onready var enemy_sprite = $TextureRect

var max_health: int = 100
var current_health: int = 100

func _ready():
	# Inicializar UI
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# --- CONECTARSE AL SIGNALBUS ---
	# Escuchamos al tablero sin conocerlo directamente
	SignalBus.match_found.connect(_on_match_made)

func _on_match_made(type: int, amount: int):
	# Aquí defines las reglas de tu RPG
	# Por ejemplo:
	# Tipo 0 (Rojo) = Ataque Fuerte
	# Tipo 1 (Azul) = Ataque Mágico (o Escudo)
	# Tipo 2 (Verde) = Poco daño
	
	var damage = 0
	
	match type:
		0: damage = amount * 10 # Rojo pega duro
		1: damage = amount * 5
		2: damage = amount * 2
		3: damage = amount * 5
		_: damage = amount # Default
	
	take_damage(damage)

func take_damage(amount: int):
	current_health -= amount
	if current_health < 0: current_health = 0
	
	# Animación de la barra (Tween para que baje suave)
	var tween = create_tween()
	tween.tween_property(health_bar, "value", current_health, 0.3).set_trans(Tween.TRANS_SINE)
	
	# Feedback visual en el enemigo (Flash blanco)
	var flash_tween = create_tween()
	enemy_sprite.modulate = Color(10, 10, 10) # Blanco brillante
	flash_tween.tween_property(enemy_sprite, "modulate", Color.RED, 0.2) # Volver a rojo
	
	print("Enemigo recibió ", amount, " de daño. Vida restante: ", current_health)
	
	if current_health == 0:
		die()

func die():
	print("¡ENEMIGO DERROTADO!")
	# Aquí podrías mostrar un panel de "VICTORY"
	enemy_sprite.hide()
	# Reiniciar para probar de nuevo (opcional)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
