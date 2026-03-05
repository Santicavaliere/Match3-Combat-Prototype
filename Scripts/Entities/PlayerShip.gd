extends Node2D # (O extends Sprite2D / AnimatedSprite2D según qué nodo sea tu PlayerShip)

@export var cannonball_scene: PackedScene
@onready var cannon_spawn = $CannonSpawn

func _ready():
	# Escuchamos cuando el CombatManager nos dice que ataquemos
	SignalBus.player_attack_requested.connect(_on_player_attack)
	# Escuchamos cuando recibimos daño
	SignalBus.player_damaged.connect(_on_player_damaged)

func _on_player_attack(dmg: int):
	# Pequeño culatazo hacia atrás (izquierda) para el jugador
	var original_pos = position
	var recoil_tween = create_tween()
	recoil_tween.tween_property(self, "position:x", -15.0, 0.1).as_relative()
	recoil_tween.tween_property(self, "position", original_pos, 0.2)
	
	# Disparamos
	fire_cannonball(dmg)

func fire_cannonball(dmg: int):
	if not cannonball_scene:
		print("ERROR: Falta cargar la escena Cannonball en el PlayerShip.")
		return
		
	var ball = cannonball_scene.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = cannon_spawn.global_position
	
	# IMPORTANTE: Como el jugador dispara hacia la derecha, le sacamos el Flip H
	# a las dos imágenes que le habíamos puesto para el enemigo.
	ball.get_node("ShotSprite").flip_h = false
	ball.get_node("BulletSprite").flip_h = false
	
	var flight_tween = create_tween()
	
	# La bala vuela hacia la DERECHA (+720 en X)
	flight_tween.tween_property(ball, "global_position:x", 800.0, 1.2).as_relative().set_trans(Tween.TRANS_LINEAR)
	
	# Cuando llega, llama al impacto y le pasa cuánto daño tiene que hacer
	flight_tween.tween_callback(strike_enemy.bind(ball, dmg))

func strike_enemy(ball_node: Node, dmg: int):
	# Buscamos el CombatManager
	var combat_manager = get_tree().current_scene.get_node_or_null("CombatManager")
	
	if combat_manager:
		# ¡ACÁ SE APLICA EL DAÑO! 
		# Esto hará que el enemigo parpadee en rojo y salte el número flotante
		combat_manager.apply_damage_to_enemy(dmg)
		
	# Borramos la bala
	ball_node.queue_free()

# --- REACCIÓN AL DAÑO ---
# --- REACCIÓN AL DAÑO ---
func _on_player_damaged(amount: int):
	# Guardamos la escala actual que le pusiste en el Inspector
	var original_scale = self.scale 
	
	# 1. Parpadeo rojo y encogimiento relativo
	self.modulate = Color.RED
	var tween = create_tween()
	
	# Lo achicamos multiplicando su escala original por 0.9 (un 10% menos)
	tween.tween_property(self, "scale", original_scale * 0.9, 0.1)
	# Lo devolvemos a su escala original exacta
	tween.tween_property(self, "scale", original_scale, 0.1)
	
	# Le devolvemos el color original
	tween.tween_property(self, "modulate", Color.WHITE, 0.3).set_delay(0.2)
	
	# 2. Mostrar el texto flotante
	show_damage_number(amount)

func show_damage_number(amount: int):
	var label = Label.new()
	label.text = "-" + str(amount)
	
	# Mismo estilo rojo que el enemigo
	label.add_theme_font_size_override("font_size", 45)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	
	# Lo posicionamos arriba del barco
	label.position = Vector2(-20, -60) 
	label.z_index = 100
	
	add_child(label)
	
	# Animación de flotar y desaparecer
	var text_tween = create_tween()
	text_tween.set_parallel(true)
	text_tween.tween_property(label, "position:y", -100.0, 1.0).as_relative()
	text_tween.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	
	text_tween.tween_callback(label.queue_free).set_delay(1.0)
