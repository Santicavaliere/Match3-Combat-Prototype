extends State
class_name EnemyTakeDamage

func enter():
	print("Enemigo: Entrando en estado TAKE_DAMAGE")
	
	context.sprite.modulate = Color.RED
	var tween = create_tween()
	
	tween.tween_property(context.sprite, "scale", context.base_scale * 0.9, 0.1)
	tween.tween_property(context.sprite, "scale", context.base_scale, 0.1)
	
	#tween.tween_property(context.sprite, "scale", Vector2(0.9, 0.9), 0.1)
	#tween.tween_property(context.sprite, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(context.sprite, "modulate", Color.WHITE, 0.3).set_delay(0.2)
	
	show_damage_number(context.last_damage_received)
	
	tween.tween_callback(finish_damage)

func show_damage_number(amount: int):
	
	var label = Label.new()
	label.text = "-" + str(amount)
	
	# --- EL FIX DE TAMAÑO ---
	# Bajamos la fuente de 45 a 18 (un tamaño más estándar)
	label.add_theme_font_size_override("font_size", 18) 
	
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2)) # Rojo
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Bajamos el borde de 8 a 3 para que no se coma la letra chica
	label.add_theme_constant_override("outline_size", 3)
	
	label.position = Vector2(-20, -60) 
	label.z_index = 100 
	
	
	context.add_child(label)
	
	
	var text_tween = create_tween()
	text_tween.set_parallel(true)
	text_tween.tween_property(label, "position:y", -100.0, 1.0).as_relative()
	text_tween.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	
	text_tween.tween_callback(label.queue_free).set_delay(1.0)

func finish_damage():
	
	var combat_manager = get_tree().current_scene.get_node("CombatManager")
	context.update_damage_vfx()
	if combat_manager and combat_manager.enemy_hp > 0:
		state_machine.change_state(state_machine.get_node("Idle"))
