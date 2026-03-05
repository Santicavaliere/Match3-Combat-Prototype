extends State
class_name EnemyAttack

func enter():
	print("Enemigo: Entrando en estado ATTACK (Disparando Cañón)")
	
	# 1. Pequeño culatazo (recoil) del barco hacia atrás
	var original_pos = context.sprite.position
	var recoil_tween = create_tween()
	recoil_tween.tween_property(context.sprite, "position:x", 15.0, 0.1).as_relative()
	recoil_tween.tween_property(context.sprite, "position", original_pos, 0.2)
	
	# 2. Instanciar y disparar la bala
	fire_cannonball()

func fire_cannonball():
	# Verificamos que hayas cargado la escena en el Inspector
	if not context.cannonball_scene:
		print("ERROR: Falta cargar la escena Cannonball en el enemigo.")
		finish_attack()
		return
		
	# Creamos la bala
	var ball = context.cannonball_scene.instantiate()
	
	# La agregamos al nivel (usamos get_tree().current_scene para que no se mueva junto con el barco enemigo)
	get_tree().current_scene.add_child(ball)
	
	# La posicionamos en el Marker2D que creaste
	ball.global_position = context.cannon_spawn.global_position
	
	# Creamos el movimiento de la bala
	var flight_tween = create_tween()
	
	# Hacemos que la bala vuele hacia la izquierda (ajustá el -600.0 según la distancia a tu barco jugador)
	flight_tween.tween_property(ball, "global_position:x", -800.0, 1.2).as_relative().set_trans(Tween.TRANS_LINEAR)
	
	# Cuando la bala llega al objetivo, llamamos a la función de impacto
	# Usamos bind(ball) para pasarle la referencia de la bala y poder borrarla
	flight_tween.tween_callback(strike_target.bind(ball))

func strike_target(ball_node: Node):
	# 1. Aplicamos el daño justo cuando la bala impacta
	SignalBus.apply_damage_to_player.emit(context.pending_damage)
	print("Enemigo: ¡PUM! Impacto de bala de ", context.pending_damage, " de daño.")
	
	# 2. Borramos la bala de la pantalla
	ball_node.queue_free()
	
	# 3. Terminamos el ataque
	finish_attack()

func finish_attack():
	# Volvemos al estado Idle
	state_machine.change_state(state_machine.get_node("Idle"))
	
	# Le avisamos al CombatManager que el turno de esta acción terminó
	SignalBus.enemy_animation_finished.emit()
