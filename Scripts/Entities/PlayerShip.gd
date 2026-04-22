extends Node2D 

# --- VISUAL COMPONENTS FOR WATER INTEGRATION ---
@onready var hull_shadow = $HullShadow
@export var cannonball_scene: PackedScene
@onready var cannon_spawn = $CannonSpawn

const MAX_EVASION_DRIFT = 6.0
var base_pos_x: float
var base_pos_y: float

# --- BOBBING VARIABLES ---
var time_passed: float = 0.0
var bob_frequency: float = 1.5 
var initial_y: float

func _ready():
	base_pos_x = position.x
	base_pos_y = position.y
	initial_y = position.y
		
	SignalBus.player_attack_requested.connect(_on_player_attack)
	SignalBus.player_damaged.connect(_on_player_damaged)
	SignalBus.helm_match_animation.connect(_play_evasion_glow)

func _process(delta: float):
	time_passed += delta
	var wave_offset = sin(time_passed * bob_frequency) * 3.0
	
	if hull_shadow:
		var current_alpha = 0.90 + (wave_offset * 0.02)
		# Color(R, G, B, Alpha). Los ceros indican negro puro.
		hull_shadow.modulate = Color(0.0, 0.0, 0.0, current_alpha)
		

func _on_player_attack(dmg: int, is_miss: bool = false, bomb_count: int = 1): 
	var recoil_tween = create_tween()
	recoil_tween.tween_property(self, "position:x", -15.0, 0.1).as_relative()
	recoil_tween.tween_property(self, "position:x", 15.0, 0.2).as_relative()
	
	for i in range(bomb_count):
		var is_last_bomb = (i == bomb_count - 1) 
		fire_cannonball(dmg, is_miss, is_last_bomb) 
		await get_tree().create_timer(0.2).timeout

func fire_cannonball(dmg: int, is_miss: bool, is_last_bomb: bool): 
	if not cannonball_scene:
		print("ERROR: Missing Cannonball scene in PlayerShip.")
		return
		
	var ball = cannonball_scene.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = cannon_spawn.global_position
	
	var flash = cannon_spawn.get_node_or_null("MuzzleFlash")
	if flash:
		flash.show()
		flash.frame = 0 
		flash.play("default") 
		flash.animation_finished.connect(flash.hide, CONNECT_ONE_SHOT)
	
	#var trail = ball.get_node_or_null("BulletTrail")
	#if trail:
		#trail.flip_h = false
		#trail.position.x = -39.0
		
	#var sprite = ball.get_node_or_null("BulletSprite")
	#if sprite:
		#sprite.flip_h = false
		#sprite.position.x = 11.0
	
	var enemy = get_tree().current_scene.find_child("EnemyShip", true, false)
	var base_enemy_x = ball.global_position.x + 800.0 
	var target_y = ball.global_position.y 
	
	if enemy:
		if enemy.has_node("ImpactPoint"):
			var impact_pos = enemy.get_node("ImpactPoint").global_position
			base_enemy_x = impact_pos.x
			target_y = impact_pos.y
		else:
			var impact_offset_x = -40.0 
			var impact_offset_y = 70.0  
			base_enemy_x = enemy.global_position.x + impact_offset_x
			target_y = enemy.global_position.y + impact_offset_y
	
	var flight_tween = create_tween()
	flight_tween.set_parallel(true)
	
	if is_miss:
		var miss_type = randi() % 2
		var flight_time = 1.5
		
		if miss_type == 0:
			var target_x = base_enemy_x - 300.0
			var target_y_final = target_y + 150.0
			var high_point = ball.global_position.y - 40.0
			
			flight_tween.tween_property(ball, "global_position:x", target_x, flight_time).set_trans(Tween.TRANS_LINEAR)
			flight_tween.tween_property(ball, "global_position:y", high_point, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			flight_tween.tween_property(ball, "global_position:y", target_y_final, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(flight_time / 2.0)
			flight_tween.tween_property(ball.get_node("BulletSprite"), "rotation", deg_to_rad(720), flight_time) 
		else:
			flight_time = 2.0 
			var target_x = base_enemy_x + 350.0 
			var target_y_final = target_y + 80.0
			var high_point = target_y - 120.0 
			
			flight_tween.tween_property(ball, "global_position:x", target_x, flight_time).set_trans(Tween.TRANS_LINEAR)
			flight_tween.tween_property(ball, "global_position:y", high_point, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			flight_tween.tween_property(ball, "global_position:y", target_y_final, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(flight_time / 2.0)
			flight_tween.tween_property(ball.get_node("BulletSprite"), "rotation", deg_to_rad(1080), flight_time) 
			
	else:
		var random_trajectory = randi() % 3
		var flight_time = 1.6
		
		match random_trajectory:
			0: 
				flight_tween.tween_property(ball, "global_position:x", base_enemy_x, flight_time).set_trans(Tween.TRANS_LINEAR)
				flight_tween.tween_property(ball, "global_position:y", target_y, flight_time).set_trans(Tween.TRANS_LINEAR)
				flight_tween.tween_property(ball.get_node("BulletSprite"), "rotation", deg_to_rad(360), flight_time) 
			1: 
				var high_point = ball.global_position.y - 60.0
				flight_tween.tween_property(ball, "global_position:x", base_enemy_x, flight_time).set_trans(Tween.TRANS_LINEAR)
				flight_tween.tween_property(ball, "global_position:y", high_point, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				flight_tween.tween_property(ball, "global_position:y", target_y, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(flight_time / 2.0)
				flight_tween.tween_property(ball.get_node("BulletSprite"), "rotation", deg_to_rad(720), flight_time) 
			2: 
				var high_point = ball.global_position.y - 110.0
				flight_tween.tween_property(ball, "global_position:x", base_enemy_x, flight_time).set_trans(Tween.TRANS_LINEAR)
				flight_tween.tween_property(ball, "global_position:y", high_point, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				flight_tween.tween_property(ball, "global_position:y", target_y, flight_time / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(flight_time / 2.0)
				flight_tween.tween_property(ball.get_node("BulletSprite"), "rotation", deg_to_rad(1080), flight_time) 
				
	flight_tween.set_parallel(false)
	flight_tween.tween_callback(strike_enemy.bind(ball, dmg, is_miss, is_last_bomb))
	
func strike_enemy(ball_node: Node, dmg: int, is_miss: bool, is_last_bomb: bool): 
	if not is_miss:
		var combat_manager = get_tree().current_scene.get_node_or_null("CombatManager")
		if combat_manager:
			combat_manager.apply_damage_to_enemy(dmg)
			
		if is_last_bomb:
			var impact_scene = preload("res://Scenes/Components/BulletImpact.tscn")
			if impact_scene:
				var impact = impact_scene.instantiate()
				get_tree().current_scene.add_child(impact)
				
				var enemy = get_tree().current_scene.find_child("EnemyShip", true, false)
				if enemy and enemy.has_node("ImpactPoint"):
					impact.global_position = enemy.get_node("ImpactPoint").global_position
				else:
					impact.global_position = ball_node.global_position 
	else:
		print("Jugador: ¡Fallo! La bomba no dio en el blanco.")
		
	SignalBus.evasion_consumed.emit(false, 0.05)
	ball_node.queue_free()

func _on_player_damaged(amount: int):
	var original_scale = self.scale 
	self.modulate = Color.RED
	var tween = create_tween()
	
	tween.tween_property(self, "scale", original_scale * 0.9, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3).set_delay(0.2)
	
	show_damage_number(amount)
	update_damage_vfx()

func show_damage_number(amount: int):
	var label = Label.new()
	label.text = "-" + str(amount)
	
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 100
	
	get_parent().add_child(label)
	label.global_position = self.global_position + Vector2(-20, -60)
	
	var text_tween = create_tween()
	text_tween.set_parallel(true)
	text_tween.tween_property(label, "global_position:y", -100.0, 1.0).as_relative()
	text_tween.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	text_tween.tween_callback(label.queue_free).set_delay(1.0)

func _play_evasion_glow():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(1.3, 1.5, 1.5), 0.3).set_trans(Tween.TRANS_SINE)
	
	var target_x = base_pos_x
	var combat_manager = get_tree().current_scene.get_node_or_null("CombatManager")
	if combat_manager:
		var drift_percent = combat_manager.player_evasion / 0.50
		target_x = base_pos_x - (MAX_EVASION_DRIFT * drift_percent)
	
	tween.tween_property(self, "position:x", target_x, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)

func update_damage_vfx():
	var combat_manager = get_tree().current_scene.get_node_or_null("CombatManager")
	if not combat_manager: return
	
	var hp_percent = float(combat_manager.player_hp) / float(combat_manager.MAX_HP)
	
	var vfx_75 = get_node_or_null("DamageVFX/Level1_75")
	var vfx_50 = get_node_or_null("DamageVFX/Level2_50")
	var vfx_25 = get_node_or_null("DamageVFX/Level3_25")
	
	if vfx_75: vfx_75.hide()
	if vfx_50: vfx_50.hide()
	if vfx_25: vfx_25.hide()

	if hp_percent <= 0.25:
		if vfx_25: vfx_25.show()
	elif hp_percent <= 0.50:
		if vfx_50: vfx_50.show()
	elif hp_percent <= 0.75:
		if vfx_75: vfx_75.show()
