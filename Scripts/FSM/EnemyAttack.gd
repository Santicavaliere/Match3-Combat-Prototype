extends State
class_name EnemyAttack

var total_bombs: int = 0
var bombs_landed: int = 0


func enter():
	print("Enemigo: Entrando en estado ATTACK (Disparando en ráfaga)")
	total_bombs = context.pending_bombs
	bombs_landed = 0
	fire_volley()

func fire_volley():
	for i in range(total_bombs):
		# NUEVO: Calculamos si es la última bala del pirata
		var is_last_bomb = (i == total_bombs - 1)
		
		var recoil_tween = create_tween()
		recoil_tween.tween_property(context.sprite, "position:x", 15.0, 0.1).as_relative()
		recoil_tween.tween_property(context.sprite, "position:x", -15.0, 0.2).as_relative()
		
		fire_cannonball(context.pending_damage, is_last_bomb) 
		
		await get_tree().create_timer(0.3).timeout

func fire_cannonball(dmg_per_bomb: int, is_last_bomb: bool):
	if not context.cannonball_scene:
		print("ERROR: Missing Cannonball scene in Enemy.")
		finish_attack()
		return
		
	var ball = context.cannonball_scene.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = context.cannon_spawn.global_position
	
	var flash = context.cannon_spawn.get_node_or_null("MuzzleFlash")
	if flash:
		flash.show()
		flash.frame = 0
		flash.play("default")
		flash.animation_finished.connect(flash.hide, CONNECT_ONE_SHOT)
	
	#var trail = ball.get_node_or_null("BulletTrail")
	#if trail: 
		#trail.flip_h = true
		#trail.position.x = 39.0
		
	#var sprite = ball.get_node_or_null("BulletSprite")
	#if sprite:
		#sprite.flip_h = true
		#sprite.position.x = -11.0
	
	var player = get_tree().current_scene.find_child("PlayerShip", true, false)
	var base_player_x = ball.global_position.x - 800.0 
	var target_y = ball.global_position.y
	
	if player:
		base_player_x = player.global_position.x
		target_y = player.global_position.y
	
	var flight_tween = create_tween()
	flight_tween.set_parallel(true)
	
	if context.pending_miss:
		var miss_type = randi() % 2
		var flight_time = 1.5
		
		if miss_type == 0:
			var target_x = base_player_x + 300.0 
			var target_y_final = target_y + 150.0
			var high_point = ball.global_position.y - 40.0
			
			flight_tween.tween_property(ball, "global_position:x", target_x, flight_time).set_trans(Tween.TRANS_LINEAR)
			flight_tween.tween_property(ball, "global_position:y", high_point, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			flight_tween.tween_property(ball, "global_position:y", target_y_final, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(flight_time / 2.0)
			flight_tween.tween_property(ball.get_node("BulletSprite"), "rotation", deg_to_rad(-720), flight_time) 
		else:
			flight_time = 2.0
			var target_x = base_player_x - 350.0 
			var target_y_final = target_y + 80.0
			var high_point = target_y - 120.0 
			
			flight_tween.tween_property(ball, "global_position:x", target_x, flight_time).set_trans(Tween.TRANS_LINEAR)
			flight_tween.tween_property(ball, "global_position:y", high_point, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			flight_tween.tween_property(ball, "global_position:y", target_y_final, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(flight_time / 2.0)
			flight_tween.tween_property(ball.get_node("BulletSprite"), "rotation", deg_to_rad(-1080), flight_time) 
			
	else:
		var random_trajectory = randi() % 3
		var flight_time = 1.6
		
		match random_trajectory:
			0: 
				flight_tween.tween_property(ball, "global_position:x", base_player_x, flight_time).set_trans(Tween.TRANS_LINEAR)
				flight_tween.tween_property(ball, "global_position:y", target_y, flight_time).set_trans(Tween.TRANS_LINEAR)
				flight_tween.tween_property(ball.get_node("BulletSprite"), "rotation", deg_to_rad(-360), flight_time) 
			1: 
				var high_point = ball.global_position.y - 60.0
				flight_tween.tween_property(ball, "global_position:x", base_player_x, flight_time).set_trans(Tween.TRANS_LINEAR)
				flight_tween.tween_property(ball, "global_position:y", high_point, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				flight_tween.tween_property(ball, "global_position:y", target_y, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(flight_time / 2.0)
				flight_tween.tween_property(ball.get_node("BulletSprite"), "rotation", deg_to_rad(-720), flight_time) 
			2: 
				var high_point = ball.global_position.y - 110.0
				flight_tween.tween_property(ball, "global_position:x", base_player_x, flight_time).set_trans(Tween.TRANS_LINEAR)
				flight_tween.tween_property(ball, "global_position:y", high_point, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				flight_tween.tween_property(ball, "global_position:y", target_y, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(flight_time / 2.0)
				flight_tween.tween_property(ball.get_node("BulletSprite"), "rotation", deg_to_rad(-1080), flight_time) 
				
	flight_tween.set_parallel(false)
	flight_tween.tween_callback(strike_target.bind(ball, dmg_per_bomb, is_last_bomb))

func strike_target(ball_node: Node, dmg_per_bomb: int, is_last_bomb: bool):
	if not context.pending_miss:
		SignalBus.apply_damage_to_player.emit(dmg_per_bomb)
		print("Enemigo: ¡PUM! Impacto de bala de ", dmg_per_bomb, " de daño.")
		
		# NUEVO: Solo explotamos si es la última bala
		if is_last_bomb:
			var impact_scene = preload("res://Scenes/Components/BulletImpact.tscn")
			if impact_scene:
				var impact = impact_scene.instantiate()
				get_tree().current_scene.add_child(impact)
				impact.flip_h = true
				
				# --- EL TARGET NODE ---
				var player = get_tree().current_scene.find_child("PlayerShip", true, false)
				# Si encuentra al jugador y el jugador tiene el nodo ImpactPoint...
				if player and player.has_node("ImpactPoint"):
					impact.global_position = player.get_node("ImpactPoint").global_position
				else:
					impact.global_position = ball_node.global_position # Fallback
	else:
		print("Enemigo: ¡Fallo catastrófico! La bala se perdió en el aire/agua.")
	
	# NUEVO: Consumir un 5% de la evasión del jugador
	SignalBus.evasion_consumed.emit(true, 0.05)
	
	ball_node.queue_free()
	
	bombs_landed += 1
	if bombs_landed >= total_bombs:
		finish_attack()

func finish_attack():
	
	state_machine.change_state(state_machine.get_node("Idle"))
	SignalBus.enemy_animation_finished.emit()
